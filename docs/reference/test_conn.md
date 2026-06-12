# test_conn

Request builders and response assertions for testing handlers without an HTTP server.

## Request builders

### `build`
```gleam
pub fn build(method: http.Method, path: String) -> Conn(BitArray)
```
Base constructor. `path` may include a query string (`/search?q=gleam`).

---

### `get` / `post` / `put` / `delete`
```gleam
pub fn get(path: String) -> Conn(BitArray)
pub fn post(path: String) -> Conn(BitArray)
pub fn put(path: String) -> Conn(BitArray)
pub fn delete(path: String) -> Conn(BitArray)
```
Convenience wrappers for `build`.

## Request modifiers

### `with_body`
```gleam
pub fn with_body(c: Conn(BitArray), body: BitArray) -> Conn(BitArray)
```

### `with_form`
```gleam
pub fn with_form(c: Conn(BitArray), params: List(#(String, String))) -> Conn(BitArray)
```
URL-encodes `params` as the body and sets `Content-Type: application/x-www-form-urlencoded`.

### `with_json`
```gleam
pub fn with_json(c: Conn(BitArray), body: String) -> Conn(BitArray)
```
Sets the body and `Content-Type: application/json`.

### `with_header`
```gleam
pub fn with_header(c: Conn(BitArray), key: String, value: String) -> Conn(BitArray)
```

### `with_session`
```gleam
pub fn with_session(c: Conn(BitArray), pairs: List(#(String, String)), secret: String) -> Conn(BitArray)
```
Signs the given key/value pairs as a session and injects the `_mw_session` cookie.

### `with_auth`
```gleam
pub fn with_auth(c: Conn(BitArray), id: Int, username: String) -> Conn(BitArray)
```
Sets `conn.auth` directly. Skips the session layer — use when you want to test a handler that `let assert Some(user) = c.auth`.

## Response helpers

### `response_body`
```gleam
pub fn response_body(resp: Response(ResponseData)) -> String
```
Extract the response body as a `String`. Returns `""` for non-bytes responses.

### `assert_status`
```gleam
pub fn assert_status(resp: Response(ResponseData), status: Int) -> Response(ResponseData)
```
Panics if the status doesn't match. Returns the response for chaining.

### `assert_redirect`
```gleam
pub fn assert_redirect(resp: Response(ResponseData), to path: String) -> Response(ResponseData)
```
Panics if the `Location` header doesn't match `path`.

### `assert_header`
```gleam
pub fn assert_header(resp: Response(ResponseData), key: String, value: String) -> Response(ResponseData)
```
Panics if the header value doesn't match.
