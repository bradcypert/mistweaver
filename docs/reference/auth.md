# auth

Session-based authentication middleware that populates `conn.auth`.

## Functions

### `load`
```gleam
pub fn load(secret: String) -> Middleware(Connection)
```
Reads the session cookie, decodes it with `secret`, and sets `conn.auth` to `Some(AuthUser)` if a valid `user_id` and `username` are present. Sets `conn.auth` to `None` and continues if the session is absent or invalid — never redirects.

Use on the outermost scope so `conn.auth` is populated for all routes.

---

### `require`
```gleam
pub fn require(secret: String, to redirect: String) -> Middleware(Connection)
```
Same as `load`, but redirects to `redirect` with a `302` if `conn.auth` is `None` after loading. Use on scopes that require a logged-in user.

## Example

```gleam
router.new()
|> router.scope("/", [auth.load(secret)], fn(r) {
  r
  |> router.get("/", home_handler)
  |> router.scope("/app", [auth.require(secret, to: "/login")], fn(r2) {
    r2 |> router.get("/dashboard", dashboard_handler)
  })
})
```
