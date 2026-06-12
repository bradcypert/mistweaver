import gleam/bit_array
import gleam/bytes_tree
import gleam/http
import gleam/http/request
import gleam/http/response.{type Response}
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleam/uri
import mist.{type ResponseData}
import mistweaver/conn.{type Conn, AuthUser, Conn}
import mistweaver/session.{type Session}

// ---------------------------------------------------------------------------
// Request builders
// ---------------------------------------------------------------------------

/// Build a Conn with a BitArray body — the type that handlers receive after
/// body_limit. Use this as the base for all test request constructors.
pub fn build(method: http.Method, path: String) -> Conn(BitArray) {
  let #(path, query) = case string.split_once(path, "?") {
    Ok(#(p, q)) -> #(p, Some(q))
    Error(_) -> #(path, None)
  }
  conn.new(
    request.Request(
      method: method,
      headers: [],
      body: <<>>,
      scheme: http.Http,
      host: "localhost",
      port: None,
      path: path,
      query: query,
    ),
  )
}

pub fn get(path: String) -> Conn(BitArray) {
  build(http.Get, path)
}

pub fn post(path: String) -> Conn(BitArray) {
  build(http.Post, path)
}

pub fn put(path: String) -> Conn(BitArray) {
  build(http.Put, path)
}

pub fn delete(path: String) -> Conn(BitArray) {
  build(http.Delete, path)
}

// ---------------------------------------------------------------------------
// Request modifiers
// ---------------------------------------------------------------------------

/// Set a raw BitArray body.
pub fn with_body(c: Conn(BitArray), body: BitArray) -> Conn(BitArray) {
  Conn(..c, request: request.Request(..c.request, body: body))
}

/// Set a URL-encoded form body and the appropriate Content-Type header.
pub fn with_form(
  c: Conn(BitArray),
  params: List(#(String, String)),
) -> Conn(BitArray) {
  let body =
    params
    |> list.map(fn(p) {
      uri.percent_encode(p.0) <> "=" <> uri.percent_encode(p.1)
    })
    |> string.join("&")
  c
  |> with_body(<<body:utf8>>)
  |> with_header("content-type", "application/x-www-form-urlencoded")
}

/// Set a JSON body and the appropriate Content-Type header.
pub fn with_json(c: Conn(BitArray), body: String) -> Conn(BitArray) {
  c
  |> with_body(<<body:utf8>>)
  |> with_header("content-type", "application/json")
}

/// Add a request header.
pub fn with_header(c: Conn(BitArray), key: String, value: String) -> Conn(BitArray) {
  Conn(
    ..c,
    request: request.set_header(c.request, key, value),
  )
}

/// Inject a signed session cookie so the handler sees the given session.
pub fn with_session(
  c: Conn(BitArray),
  sess: Session,
  secret: String,
) -> Conn(BitArray) {
  let signed = session.sign(sess, secret)
  with_header(c, "cookie", "_mw_session=" <> signed)
}

/// Set conn.auth directly — useful for testing handlers in a protected scope
/// without going through the full auth middleware.
pub fn with_auth(c: Conn(BitArray), id: Int, username: String) -> Conn(BitArray) {
  Conn(..c, auth: Some(AuthUser(id:, username:)))
}

// ---------------------------------------------------------------------------
// Response inspectors
// ---------------------------------------------------------------------------

/// Extract the response body as a String. Returns "" for non-Bytes bodies
/// (WebSocket, SSE, file responses).
pub fn response_body(resp: Response(ResponseData)) -> String {
  case resp.body {
    mist.Bytes(bt) ->
      bt
      |> bytes_tree.to_bit_array
      |> bit_array.to_string
      |> option.from_result
      |> option.unwrap("")
    _ -> ""
  }
}

/// Assert the response has the given status; return the response for chaining.
pub fn assert_status(resp: Response(ResponseData), status: Int) -> Response(ResponseData) {
  let actual = resp.status
  case actual == status {
    True -> resp
    False -> {
      let msg =
        "Expected status "
        <> string.inspect(status)
        <> " but got "
        <> string.inspect(actual)
      panic as msg
    }
  }
}

/// Assert the response redirects to the given path.
pub fn assert_redirect(
  resp: Response(ResponseData),
  to path: String,
) -> Response(ResponseData) {
  let location =
    response.get_header(resp, "location") |> option.from_result |> option.unwrap("")
  case location == path {
    True -> resp
    False -> {
      let msg = "Expected redirect to " <> path <> " but got " <> location
      panic as msg
    }
  }
}

/// Assert a response header has the given value.
pub fn assert_header(
  resp: Response(ResponseData),
  key: String,
  value: String,
) -> Response(ResponseData) {
  let actual =
    response.get_header(resp, key) |> option.from_result |> option.unwrap("")
  case actual == value {
    True -> resp
    False -> {
      let msg =
        "Expected header "
        <> key
        <> ": "
        <> value
        <> " but got: "
        <> actual
      panic as msg
    }
  }
}
