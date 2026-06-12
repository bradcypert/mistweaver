# Mistweaver

A Phoenix-inspired web framework for [Gleam](https://gleam.run), built on [Mist](https://github.com/rawhat/mist) and [Lustre](https://lustre.build).

**[Documentation →](https://bradcypert.github.io/mistweaver/)**

## Features

- Scoped routing with composable middleware pipelines
- `Conn` model — auth, assigns, and request in one typed value
- LiveView powered by Lustre — real-time UIs, no client-side framework required
- Sessions, flash messages, and CSRF protection built in
- Forms and changeset-based validation
- Multipart / file upload parsing
- PubSub via Erlang's `pg` process groups
- Mailer with log and test adapters
- Environment-based config with fail-fast boot
- Structured telemetry events
- Test utilities for handler testing without an HTTP server

## Quick start

```sh
gleam add mistweaver
```

```gleam
import gleam/erlang/process
import mist.{type Connection}
import mistweaver
import mistweaver/response as mw_response
import mistweaver/router

pub fn main() {
  let r =
    router.new()
    |> router.get("/", fn(_conn, _params) {
      mw_response.html(200, "<h1>Hello from Mistweaver!</h1>")
    })

  let assert Ok(_) =
    mistweaver.new_config()
    |> mistweaver.port(4000)
    |> mistweaver.start(r)

  process.sleep_forever()
}
```

See the [full guide](https://bradcypert.github.io/mistweaver/guide/introduction) for routing, auth, LiveView, and more.

## Example app

[`examples/chirp`](examples/chirp) — a Twitter-style microblog built on Mistweaver. Demonstrates routing, auth, LiveView, sessions, flash, and changesets end-to-end.

## License

Apache 2.0
