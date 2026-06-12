# Conn

`Conn` is the central type in Mistweaver. It wraps the raw HTTP request and carries auth and assigns through the middleware pipeline.

```gleam
pub type Conn(body) {
  Conn(
    request: Request(body),
    auth: Option(AuthUser),
    assigns: Dict(String, String),
  )
}
```

## AuthUser

When `auth.load` or `auth.require` middleware runs, it populates `conn.auth`:

```gleam
pub type AuthUser {
  AuthUser(id: Int, username: String)
}
```

Access it directly in any handler:

```gleam
fn(c, _params) {
  case c.auth {
    Some(user) -> mw_response.html(200, "Hello " <> user.username)
    None       -> mw_response.redirect(302, to: "/login")
  }
}
```

With `auth.require` middleware on the scope, you can use `let assert` since `None` is impossible:

```gleam
fn(c, _params) {
  let assert Some(user) = c.auth
  // user is guaranteed present
}
```

## Assigns

Store arbitrary string values for use downstream in a pipeline:

```gleam
// In middleware:
Conn(..c, assigns: dict.insert(c.assigns, "request_id", id))

// In a handler:
let req_id = dict.get(c.assigns, "request_id") |> result.unwrap("unknown")
```

## Accessing the request

The underlying `gleam/http/request.Request` is always at `c.request`:

```gleam
let host = c.request.host
let method = c.request.method
let path = c.request.path
```
