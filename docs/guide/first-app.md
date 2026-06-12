# Your First App

A minimal Mistweaver server in three files.

## `src/hello.gleam`

```gleam
import gleam/erlang/process
import mistweaver
import hello/router

pub fn main() {
  let router = router.build()

  let assert Ok(_) =
    mistweaver.new_config()
    |> mistweaver.port(4000)
    |> mistweaver.start(router)

  process.sleep_forever()
}
```

## `src/hello/router.gleam`

```gleam
import mist.{type Connection}
import mistweaver/response as mw_response
import mistweaver/router

pub fn build() -> router.Router(Connection) {
  router.new()
  |> router.get("/", fn(_conn, _params) {
    mw_response.html(200, "<h1>Hello from Mistweaver!</h1>")
  })
}
```

Run it:

```sh
gleam run
# → http://localhost:4000
```

## Adding a scope

Group routes under a path prefix with shared middleware:

```gleam
import mistweaver/middleware
import mistweaver/rescue

router.new()
|> router.scope("/", [rescue.middleware, middleware.logger], fn(r) {
  r
  |> router.get("/", home_handler)
  |> router.get("/about", about_handler)
})
```

Middleware runs in order, outermost first. `rescue.middleware` should always be first so it catches crashes in everything below it.
