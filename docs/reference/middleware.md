# middleware

Built-in middleware functions. All follow the `fn(Conn(body), fn(Conn(body)) -> Response) -> Response` signature.

## Types

```gleam
pub type CorsOptions {
  CorsOptions(
    allow_origins: List(String),
    allow_methods: List(String),
    allow_headers: List(String),
    max_age_seconds: Option(Int),
  )
}
```

## Functions

### `log`
```gleam
pub fn log(c: Conn(Connection), next: fn(Conn(Connection)) -> Response(ResponseData)) -> Response(ResponseData)
```
Logs method, path, status code, and duration using the `logging` library.

---

### `request_id`
```gleam
pub fn request_id(c: Conn(body), next: fn(Conn(body)) -> Response(ResponseData)) -> Response(ResponseData)
```
Reads `X-Request-Id` from the incoming request; generates a UUID v4 if absent. Sets `X-Request-Id` on the response.

---

### `cors`
```gleam
pub fn cors(opts: CorsOptions, c: Conn(body), next: fn(Conn(body)) -> Response(ResponseData)) -> Response(ResponseData)
```
Adds CORS headers based on `opts`. Handles `OPTIONS` preflight requests with a `204` response.

---

### `cors_allow_all`
```gleam
pub fn cors_allow_all() -> CorsOptions
```
Returns permissive `CorsOptions` with `*` origin and common methods. Useful for development.

---

### `static_files`
```gleam
pub fn static_files(under prefix: String, from dir: String) -> Middleware(Connection)
```
Serves files from `dir` on disk under the given URL `prefix`.

---

### `body_limit`
```gleam
pub fn body_limit(limit_bytes: Int) -> Middleware(Connection)
```
Reads and buffers the full request body, rejecting requests larger than `limit_bytes` with `413`. Converts `Conn(Connection)` to `Conn(BitArray)` for downstream handlers.
