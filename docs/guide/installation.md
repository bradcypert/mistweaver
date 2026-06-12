# Installation

## Requirements

- Gleam `>= 1.0`
- Erlang/OTP `>= 26`

## Adding to a project

```sh
gleam add mistweaver
```

Mistweaver pulls in `mist`, `gleam_http`, `gleam_erlang`, `gleam_otp`, `gleam_crypto`, and `lustre` as transitive dependencies.

## Minimal `gleam.toml`

```toml
[dependencies]
gleam_stdlib = ">= 1.0.0 and < 2.0.0"
mistweaver = ">= 1.0.0 and < 2.0.0"
```

## Project layout

There is no required directory structure. A typical project looks like:

```
src/
  myapp.gleam          # main entry point
  myapp/
    router.gleam       # route definitions
    controllers/       # handler functions
    live/              # LiveView components
```
