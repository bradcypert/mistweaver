import gleam/bit_array
import gleam/http/request.{type Request}
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
import gleam/uri

/// Look up a path parameter by name from the params list captured during routing.
pub fn path_param(params: List(#(String, String)), key: String) -> Option(String) {
  params
  |> list.find(fn(pair) { pair.0 == key })
  |> result.map(fn(pair) { pair.1 })
  |> option.from_result
}

/// Look up a query string parameter by name.
pub fn query_param(req: Request(body), key: String) -> Option(String) {
  req
  |> request.get_query
  |> result.unwrap([])
  |> list.find(fn(pair) { pair.0 == key })
  |> result.map(fn(pair) { pair.1 })
  |> option.from_result
}

/// Get all query string parameters as a list of key/value pairs.
pub fn query_params(req: Request(body)) -> List(#(String, String)) {
  req
  |> request.get_query
  |> result.unwrap([])
}

/// Get a request header value by name (case-insensitive per HTTP spec).
pub fn get_header(req: Request(body), key: String) -> Option(String) {
  request.get_header(req, key)
  |> option.from_result
}

/// Return the request path as a list of non-empty segments.
pub fn path_segments(req: Request(body)) -> List(String) {
  req.path
  |> string.split("/")
  |> list.filter(fn(s) { s != "" })
}

/// Return the full request URI as a string.
pub fn uri(req: Request(body)) -> String {
  uri.to_string(request.to_uri(req))
}

/// Return the raw path string.
pub fn path(req: Request(body)) -> String {
  req.path
}

/// Require a path param; returns Error if missing. Useful in handlers where
/// routing has already guaranteed the param exists.
pub fn require_path_param(
  params: List(#(String, String)),
  key: String,
) -> Result(String, String) {
  path_param(params, key)
  |> option.to_result("missing required path param: " <> key)
}

/// Require a non-empty query param; returns Error if absent or empty.
pub fn require_query_param(
  req: Request(body),
  key: String,
) -> Result(String, String) {
  query_param(req, key)
  |> option.map(fn(v) {
    case string.is_empty(v) {
      True -> Error("query param '" <> key <> "' is empty")
      False -> Ok(v)
    }
  })
  |> option.unwrap(Error("missing required query param: " <> key))
}

/// Return the value of a cookie by name. Parses the Cookie header lazily.
pub fn get_cookie(req: Request(body), name: String) -> Option(String) {
  req
  |> request.get_header("cookie")
  |> result.map(parse_cookies)
  |> result.unwrap([])
  |> list.find(fn(pair) { pair.0 == name })
  |> result.map(fn(pair) { pair.1 })
  |> option.from_result
}

/// Parse URL-encoded form data from a request with a pre-read body.
/// Use after `middleware.body_limit` which converts `Request(Connection)`
/// to `Request(BitArray)`.
pub fn form_params(req: Request(BitArray)) -> List(#(String, String)) {
  case bit_array.to_string(req.body) {
    Ok(body) -> parse_form_body(body)
    Error(_) -> []
  }
}

/// Look up a single form field by name from a pre-parsed form params list.
pub fn form_param(
  params: List(#(String, String)),
  key: String,
) -> option.Option(String) {
  params
  |> list.find(fn(pair) { pair.0 == key })
  |> result.map(fn(pair) { pair.1 })
  |> option.from_result
}

fn parse_form_body(body: String) -> List(#(String, String)) {
  case body {
    "" -> []
    _ ->
      body
      |> string.split("&")
      |> list.filter_map(fn(pair) {
        case string.split_once(pair, "=") {
          Ok(#(k, v)) -> {
            let dk = uri.percent_decode(k) |> result.unwrap(k)
            let dv = uri.percent_decode(v) |> result.unwrap(v)
            Ok(#(dk, dv))
          }
          Error(_) -> Error(Nil)
        }
      })
  }
}

fn parse_cookies(header: String) -> List(#(String, String)) {
  header
  |> string.split(";")
  |> list.filter_map(fn(pair) {
    case string.split_once(string.trim(pair), "=") {
      Ok(#(k, v)) -> Ok(#(string.trim(k), string.trim(v)))
      Error(_) -> Error(Nil)
    }
  })
}
