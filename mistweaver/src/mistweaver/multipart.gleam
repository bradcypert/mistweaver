import gleam/bit_array
import gleam/http/request.{type Request}
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string

/// A single part from a multipart/form-data request.
pub type Part {
  /// A plain form field.
  Field(name: String, value: String)
  /// A file upload.
  Upload(
    name: String,
    filename: String,
    content_type: String,
    data: BitArray,
  )
}

/// Parse a multipart/form-data request body into a list of parts.
/// Returns an error if the Content-Type is missing, the boundary is absent,
/// or the body cannot be decoded.
///
///   case multipart.parse(conn.request) {
///     Ok(parts) -> handle_parts(parts)
///     Error(e)  -> mw_response.bad_request(e)
///   }
pub fn parse(req: Request(BitArray)) -> Result(List(Part), String) {
  use boundary <- result.try(get_boundary(req))
  case bit_array.to_string(req.body) {
    Error(_) -> Error("request body is not valid UTF-8")
    Ok(body) -> Ok(parse_parts(body, boundary))
  }
}

/// Look up a field value by name from a parsed parts list.
pub fn get_field(parts: List(Part), name: String) -> option.Option(String) {
  list.find_map(parts, fn(part) {
    case part {
      Field(n, value) if n == name -> Ok(value)
      _ -> Error(Nil)
    }
  })
  |> option.from_result
}

/// Return all Upload parts from a parsed list.
pub fn uploads(parts: List(Part)) -> List(Part) {
  list.filter(parts, fn(part) {
    case part {
      Upload(..) -> True
      _ -> False
    }
  })
}

// ---------------------------------------------------------------------------
// Internals
// ---------------------------------------------------------------------------

fn get_boundary(req: Request(a)) -> Result(String, String) {
  case request.get_header(req, "content-type") {
    Error(_) -> Error("missing Content-Type header")
    Ok(ct) ->
      case string.contains(ct, "multipart/form-data") {
        False -> Error("Content-Type is not multipart/form-data")
        True ->
          case string.split_once(ct, "boundary=") {
            Error(_) -> Error("missing boundary in Content-Type")
            Ok(#(_, b)) -> Ok(string.trim(b) |> string.replace("\"", ""))
          }
      }
  }
}

fn parse_parts(body: String, boundary: String) -> List(Part) {
  let delimiter = "--" <> boundary
  body
  |> string.split(delimiter)
  |> list.drop(1)
  |> list.filter_map(fn(chunk) {
    let trimmed = string.trim_start(chunk)
    case
      string.starts_with(trimmed, "--"),
      string.is_empty(string.trim(chunk))
    {
      True, _ -> Error(Nil)
      _, True -> Error(Nil)
      _, _ -> parse_part(chunk)
    }
  })
}

fn parse_part(chunk: String) -> Result(Part, Nil) {
  let normalized = string.replace(chunk, "\r\n", "\n")
  case string.split_once(normalized, "\n\n") {
    Error(_) -> Error(Nil)
    Ok(#(headers_str, body)) -> {
      let headers = parse_headers(headers_str)
      let body_trimmed = case string.ends_with(body, "\n") {
        True -> string.drop_end(body, 1)
        False -> body
      }
      case get_header(headers, "content-disposition") {
        None -> Error(Nil)
        Some(disposition) -> {
          let name = extract_param(disposition, "name") |> option.unwrap("")
          case extract_param(disposition, "filename") {
            None -> Ok(Field(name: name, value: body_trimmed))
            Some(filename) -> {
              let ct =
                get_header(headers, "content-type")
                |> option.unwrap("application/octet-stream")
              Ok(Upload(
                name: name,
                filename: filename,
                content_type: ct,
                data: <<body_trimmed:utf8>>,
              ))
            }
          }
        }
      }
    }
  }
}

fn parse_headers(headers_str: String) -> List(#(String, String)) {
  headers_str
  |> string.split("\n")
  |> list.filter_map(fn(line) {
    case string.split_once(line, ":") {
      Error(_) -> Error(Nil)
      Ok(#(key, value)) ->
        Ok(#(string.lowercase(string.trim(key)), string.trim(value)))
    }
  })
}

fn get_header(
  headers: List(#(String, String)),
  key: String,
) -> option.Option(String) {
  list.find(headers, fn(h) { h.0 == key })
  |> result.map(fn(h) { h.1 })
  |> option.from_result
}

fn extract_param(header_value: String, param: String) -> option.Option(String) {
  let search = param <> "="
  case string.split_once(header_value, search) {
    Error(_) -> None
    Ok(#(_, rest)) -> {
      let value = case string.starts_with(rest, "\"") {
        True ->
          rest
          |> string.drop_start(1)
          |> string.split_once("\"")
          |> result.map(fn(p) { p.0 })
          |> option.from_result
          |> option.unwrap("")
        False ->
          case string.split_once(rest, ";") {
            Ok(#(v, _)) -> string.trim(v)
            Error(_) -> string.trim(rest)
          }
      }
      Some(value)
    }
  }
}
