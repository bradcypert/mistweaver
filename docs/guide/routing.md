# Routing

## Basic routes

```gleam
router.new()
|> router.get("/posts", posts_ctrl.index)
|> router.post("/posts", posts_ctrl.create)
|> router.get("/posts/:id", posts_ctrl.show)
|> router.put("/posts/:id", posts_ctrl.update)
|> router.delete("/posts/:id", posts_ctrl.destroy)
```

A handler has the signature:

```gleam
fn(Conn(body), List(#(String, String))) -> Response(ResponseData)
```

The second argument is the matched path parameters.

## Path parameters

```gleam
import mistweaver/request as mw_request

router.get("/users/:username", fn(c, params) {
  let username = mw_request.path_param(params, "username") |> option.unwrap("")
  mw_response.html(200, "Hello " <> username)
})
```

## Wildcard routes

```gleam
router.get("/static/*", fn(_c, _params) { mw_response.not_found() })
```

## Scopes

Scopes group routes under a prefix with shared middleware:

```gleam
router.scope("/api", [middleware.json_headers], fn(r) {
  r
  |> router.get("/users", users_ctrl.index)
  |> router.post("/users", users_ctrl.create)
})
```

Scopes nest:

```gleam
router.scope("/", [rescue.middleware, auth.load(secret)], fn(r) {
  r
  |> router.get("/", home)
  |> router.scope("/admin", [auth.require(secret, to: "/login")], fn(r2) {
    r2
    |> router.get("/dashboard", admin_ctrl.dashboard)
  })
})
```

## Static files

```gleam
router.scope("/static", [middleware.static_files(
  under: "/static",
  from: "priv/static",
)], fn(s) {
  s |> router.get("/*", fn(_c, _params) { mw_response.not_found() })
})
```
