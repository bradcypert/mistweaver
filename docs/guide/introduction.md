# Introduction

Mistweaver is a web framework for [Gleam](https://gleam.run) built on top of [Mist](https://github.com/rawhat/mist) and [Lustre](https://lustre.build). It takes the patterns that make Phoenix productive — scoped routing, a `conn` model, middleware pipelines, LiveView — and expresses them in Gleam's type system with no macros and no magic.

## Design goals

- **No hidden state.** The `Conn` type carries everything a handler needs. Auth, session, assigns — all explicit fields.
- **Middleware as functions.** A middleware is just `fn(Conn, fn(Conn) -> Response) -> Response`. No special registration, no global mutable pipeline.
- **LiveView without JavaScript.** Lustre handles the client side. Mistweaver handles mounting, auth injection, and the WebSocket lifecycle.
- **Fail fast.** `config.require/1` panics at boot if a variable is missing. `rescue.middleware` catches crashes at request time so one bad handler can't take down the server.

## What it is not

Mistweaver is not a full-stack framework with an ORM, asset pipeline, or generator tooling. It wraps Mist (HTTP), Gloo (database), and Lustre (UI) and provides the glue between them.

## Next steps

- [Installation](/guide/installation) — add Mistweaver to a new project
- [Your First App](/guide/first-app) — build a minimal working server
- [Routing](/guide/routing) — define routes and scopes
