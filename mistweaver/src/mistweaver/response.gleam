import gleam/bytes_tree
import gleam/http/response.{type Response}
import gleam/json
import gleam/string_tree
import mist.{type ResponseData}

/// Plain 200 OK with no body.
pub fn ok() -> Response(ResponseData) {
  response.new(200)
  |> response.set_body(mist.Bytes(bytes_tree.new()))
}

/// Respond with a UTF-8 HTML body.
pub fn html(status: Int, body: String) -> Response(ResponseData) {
  response.new(status)
  |> response.set_header("content-type", "text/html; charset=utf-8")
  |> response.set_body(
    body
    |> string_tree.from_string
    |> bytes_tree.from_string_tree
    |> mist.Bytes,
  )
}

/// Respond with a JSON body. Accepts a `gleam/json.Json` value.
pub fn json(status: Int, value: json.Json) -> Response(ResponseData) {
  let body = json.to_string(value)
  response.new(status)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(
    body
    |> string_tree.from_string
    |> bytes_tree.from_string_tree
    |> mist.Bytes,
  )
}

/// Respond with a plain text body.
pub fn text(status: Int, body: String) -> Response(ResponseData) {
  response.new(status)
  |> response.set_header("content-type", "text/plain; charset=utf-8")
  |> response.set_body(
    body
    |> string_tree.from_string
    |> bytes_tree.from_string_tree
    |> mist.Bytes,
  )
}

/// Respond with raw bytes and a given content-type.
pub fn bytes(
  status: Int,
  content_type: String,
  body: BitArray,
) -> Response(ResponseData) {
  response.new(status)
  |> response.set_header("content-type", content_type)
  |> response.set_body(mist.Bytes(bytes_tree.from_bit_array(body)))
}

/// Issue a redirect. Use status 301 for permanent, 302 for temporary.
pub fn redirect(status: Int, to location: String) -> Response(ResponseData) {
  response.new(status)
  |> response.set_header("location", location)
  |> response.set_body(mist.Bytes(bytes_tree.new()))
}

/// 404 Not Found with an empty body.
pub fn not_found() -> Response(ResponseData) {
  response.new(404)
  |> response.set_body(mist.Bytes(bytes_tree.new()))
}

/// 400 Bad Request with an optional message.
pub fn bad_request(message: String) -> Response(ResponseData) {
  text(400, message)
}

/// 500 Internal Server Error with an optional message.
pub fn internal_server_error(message: String) -> Response(ResponseData) {
  text(500, message)
}

/// 201 Created, typically with a Location header pointing at the new resource.
pub fn created(location: String) -> Response(ResponseData) {
  response.new(201)
  |> response.set_header("location", location)
  |> response.set_body(mist.Bytes(bytes_tree.new()))
}

/// 204 No Content.
pub fn no_content() -> Response(ResponseData) {
  response.new(204)
  |> response.set_body(mist.Bytes(bytes_tree.new()))
}

/// Add or replace a response header on an existing response.
pub fn put_header(
  resp: Response(ResponseData),
  key: String,
  value: String,
) -> Response(ResponseData) {
  response.set_header(resp, key, value)
}
