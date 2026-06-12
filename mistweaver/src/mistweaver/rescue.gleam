import gleam/bytes_tree
import gleam/http/response
import mist.{type ResponseData}
import mistweaver/conn.{type Conn}

/// Wrap the downstream handler in a try/catch. Any unhandled error — a
/// failed `assert`, a runtime crash, or an explicit `panic` — is caught,
/// logged via Erlang's logger, and turned into a plain 500 response.
///
/// Add as the outermost scope middleware so it covers the entire stack:
///
///   router.new()
///   |> router.scope("/", [rescue.middleware], fn(r) { ... })
pub fn middleware(
  c: Conn(body),
  next: fn(Conn(body)) -> response.Response(ResponseData),
) -> response.Response(ResponseData) {
  case try_call(fn() { next(c) }) {
    Ok(resp) -> resp
    Error(_) ->
      response.new(500)
      |> response.set_header("content-type", "text/html; charset=utf-8")
      |> response.set_body(
        mist.Bytes(bytes_tree.from_string(
          "<!doctype html><html><body>"
          <> "<h1>500 Internal Server Error</h1>"
          <> "<p>Something went wrong. Please try again.</p>"
          <> "</body></html>",
        )),
      )
  }
}

@external(erlang, "mistweaver_rescue_ffi", "try_call")
fn try_call(f: fn() -> a) -> Result(a, Nil)
