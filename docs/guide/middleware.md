# Middleware

A middleware is a function with this signature:

```gleam
fn(Conn(body), fn(Conn(body)) -> Response(ResponseData)) -> Response(ResponseData)
```

It receives the current conn, calls `next(conn)` to continue the pipeline, and can inspect or modify the conn before and the response after.

## Built-in middleware

| Middleware | Description |
|---|---|
| `rescue.middleware` | Catches crashes, returns 500 |
| `middleware.logger` | Logs method, path, status, and duration |
| `middleware.body_limit(n)` | Reads and limits the request body |
| `middleware.static_files(under:, from:)` | Serves files from disk |
| `auth.load(secret)` | Populates `conn.auth` from session |
| `auth.require(secret, to:)` | Redirects to `to` if unauthenticated |

## Writing middleware

```gleam
fn request_id_middleware(
  c: Conn(body),
  next: fn(Conn(body)) -> Response(ResponseData),
) -> Response(ResponseData) {
  let id = generate_id()
  let c2 = Conn(..c, assigns: dict.insert(c.assigns, "request_id", id))
  next(c2)
  |> response.set_header("x-request-id", id)
}
```

Pass it to a scope:

```gleam
router.scope("/", [request_id_middleware], fn(r) { ... })
```

## Order

Middleware in a scope list runs outermost-first on the way in, innermost-first on the way out — like `plug` in Phoenix. Put `rescue.middleware` first so it wraps everything else.

```gleam
[rescue.middleware, auth.load(secret), logger_middleware]
//  ↑ wraps all of ↓
```
