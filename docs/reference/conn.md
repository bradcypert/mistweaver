# conn

The `Conn` type carries the HTTP request, authenticated user, and assigns through every middleware and handler.

## Types

```gleam
pub type AuthUser {
  AuthUser(id: Int, username: String)
}

pub type Conn(body) {
  Conn(
    request: Request(body),
    auth: Option(AuthUser),
    assigns: Dict(String, String),
  )
}
```

## Functions

### `new`
```gleam
pub fn new(req: Request(body)) -> Conn(body)
```
Wrap a raw request in a `Conn` with no auth and empty assigns. Called automatically by `router.dispatch`.

## Working with Conn

**Reading auth:**
```gleam
case c.auth {
  Some(user) -> user.username
  None -> "anonymous"
}
```

**Writing assigns:**
```gleam
Conn(..c, assigns: dict.insert(c.assigns, "key", "value"))
```
