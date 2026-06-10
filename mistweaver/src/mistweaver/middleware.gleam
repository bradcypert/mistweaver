import birl
import gleam/bit_array
import gleam/bytes_tree
import gleam/crypto
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import logging
import mist.{type Connection, type ResponseData}
import mistweaver/router.{type Middleware}

// ---------------------------------------------------------------------------
// Generic middleware — works with any request body type
// ---------------------------------------------------------------------------

/// Log each request with method, path, status, and elapsed time.
/// Intended for the outermost layer of the middleware stack.
pub fn log(
  req: Request(body),
  next: fn(Request(body)) -> Response(ResponseData),
) -> Response(ResponseData) {
  let start = birl.monotonic_now()
  let resp = next(req)
  let elapsed_ms = { birl.monotonic_now() - start } / 1000
  logging.log(
    logging.Info,
    method_string(req.method)
      <> " "
      <> req.path
      <> " → "
      <> int.to_string(resp.status)
      <> " ("
      <> int.to_string(elapsed_ms)
      <> "ms)",
  )
  resp
}

/// Generate (or propagate) an `x-request-id` header on both the request
/// passed downstream and the response returned upstream. Downstream handlers
/// can read the ID via `request.get_header(req, "x-request-id")`.
pub fn request_id(
  req: Request(body),
  next: fn(Request(body)) -> Response(ResponseData),
) -> Response(ResponseData) {
  let id = case request.get_header(req, "x-request-id") {
    Ok(existing) -> existing
    Error(_) -> generate_id()
  }
  let req2 = request.set_header(req, "x-request-id", id)
  next(req2)
  |> response.set_header("x-request-id", id)
}

pub type CorsOptions {
  CorsOptions(
    allow_origins: List(String),
    allow_methods: List(String),
    allow_headers: List(String),
    max_age_seconds: option.Option(Int),
  )
}

/// Permissive CORS defaults — allow everything. Use as a starting point and
/// tighten for production.
pub fn cors_allow_all() -> CorsOptions {
  CorsOptions(
    allow_origins: ["*"],
    allow_methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers: ["content-type", "authorization", "x-request-id"],
    max_age_seconds: Some(86_400),
  )
}

/// Add CORS headers to every response. Automatically handles `OPTIONS`
/// preflight requests by returning 204 without calling `next`.
pub fn cors(
  options: CorsOptions,
  req: Request(body),
  next: fn(Request(body)) -> Response(ResponseData),
) -> Response(ResponseData) {
  let origin = request.get_header(req, "origin") |> option_from_result
  let allow_origin = case options.allow_origins {
    ["*"] -> "*"
    origins ->
      case origin {
        Some(o) ->
          case list.contains(origins, o) {
            True -> o
            False -> ""
          }
        None -> ""
      }
  }

  let add_cors = fn(resp: Response(ResponseData)) {
    resp
    |> response.set_header("access-control-allow-origin", allow_origin)
    |> response.set_header(
      "access-control-allow-methods",
      string.join(options.allow_methods, ", "),
    )
    |> response.set_header(
      "access-control-allow-headers",
      string.join(options.allow_headers, ", "),
    )
    |> fn(r) {
      case options.max_age_seconds {
        Some(age) ->
          response.set_header(
            r,
            "access-control-max-age",
            int.to_string(age),
          )
        None -> r
      }
    }
  }

  case req.method {
    http.Options ->
      response.new(204)
      |> response.set_body(mist.Bytes(bytes_tree.new()))
      |> add_cors

    _ ->
      next(req)
      |> add_cors
  }
}

// ---------------------------------------------------------------------------
// Connection-specific middleware — requires a real Mist connection
// ---------------------------------------------------------------------------

/// Serve static files from `dir` for any request whose path starts with
/// `prefix`. Strips the prefix before looking up the file on disk.
/// Falls through to `next` when no matching file is found.
///
///   middleware.static_files(under: "/static", from: "priv/static")
pub fn static_files(
  under prefix: String,
  from dir: String,
) -> Middleware(Connection) {
  fn(req: Request(Connection), next: fn(Request(Connection)) -> Response(ResponseData)) {
    case string.starts_with(req.path, prefix) {
      False -> next(req)
      True -> {
        let rel = string.drop_start(req.path, string.length(prefix))
        let file_path = case string.starts_with(rel, "/") {
          True -> dir <> rel
          False -> dir <> "/" <> rel
        }
        case mist.send_file(file_path, offset: 0, limit: None) {
          Ok(body) ->
            response.new(200)
            |> response.set_header("content-type", guess_content_type(file_path))
            |> response.set_body(body)
          Error(_) -> next(req)
        }
      }
    }
  }
}

/// Enforce a maximum request body size. Reads the body eagerly up to
/// `max_bytes`; if the body is too large, returns 413 immediately.
/// Downstream handlers receive `Request(BitArray)` with the pre-read body.
///
/// Because this changes the request body type from `Connection` to
/// `BitArray`, it must be the innermost Connection-specific middleware.
/// The handler it wraps must accept `Request(BitArray)`.
pub fn body_limit(
  max_bytes: Int,
  handler: fn(Request(BitArray)) -> Response(ResponseData),
) -> Middleware(Connection) {
  fn(req: Request(Connection), _next: fn(Request(Connection)) -> Response(ResponseData)) {
    case mist.read_body(req, max_bytes) {
      Ok(req_with_body) -> handler(req_with_body)
      Error(mist.ExcessBody) ->
        response.new(413)
        |> response.set_body(mist.Bytes(bytes_tree.new()))
      Error(mist.MalformedBody) ->
        response.new(400)
        |> response.set_body(mist.Bytes(bytes_tree.new()))
    }
  }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

fn method_string(method: http.Method) -> String {
  case method {
    http.Get -> "GET"
    http.Post -> "POST"
    http.Put -> "PUT"
    http.Patch -> "PATCH"
    http.Delete -> "DELETE"
    http.Head -> "HEAD"
    http.Options -> "OPTIONS"
    http.Trace -> "TRACE"
    http.Connect -> "CONNECT"
    http.Other(s) -> string.uppercase(s)
  }
}

fn generate_id() -> String {
  crypto.strong_random_bytes(16)
  |> bit_array.base16_encode
  |> string.lowercase
}

fn guess_content_type(path: String) -> String {
  case string.split(path, ".") |> list.last {
    Ok("html") | Ok("htm") -> "text/html; charset=utf-8"
    Ok("css") -> "text/css"
    Ok("js") | Ok("mjs") -> "application/javascript"
    Ok("json") -> "application/json"
    Ok("png") -> "image/png"
    Ok("jpg") | Ok("jpeg") -> "image/jpeg"
    Ok("gif") -> "image/gif"
    Ok("svg") -> "image/svg+xml"
    Ok("ico") -> "image/x-icon"
    Ok("woff") -> "font/woff"
    Ok("woff2") -> "font/woff2"
    Ok("ttf") -> "font/ttf"
    Ok("txt") -> "text/plain; charset=utf-8"
    Ok("xml") -> "application/xml"
    Ok("pdf") -> "application/pdf"
    Ok("webp") -> "image/webp"
    _ -> "application/octet-stream"
  }
}

fn option_from_result(r: Result(a, e)) -> option.Option(a) {
  case r {
    Ok(v) -> Some(v)
    Error(_) -> None
  }
}
