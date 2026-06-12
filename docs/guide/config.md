# Config

The `config` module reads environment variables. It is intended for use at application startup, not inside request handlers.

## Reading values

```gleam
import mistweaver/config

// Option(String) — None if unset
let maybe_secret = config.get("APP_SECRET")

// String with a default fallback
let secret = config.get_or("APP_SECRET", "dev-secret-change-me")

// String — panics at boot if unset
let secret = config.require("APP_SECRET_KEY_BASE")
```

## Pattern: fail fast at boot

Use `config.require` for values that the application cannot start without. A clear panic at boot is better than a confusing runtime error during a request:

```gleam
pub fn main() {
  let secret = config.require("APP_SECRET_KEY_BASE")
  let db_url = config.require("DATABASE_URL")
  ...
}
```

## Pattern: dev defaults

Use `config.get_or` for values that have sensible development defaults:

```gleam
let secret = config.get_or("APP_SECRET_KEY_BASE", "dev-only-secret")
let port   = config.get_or("PORT", "4000") |> int.parse |> result.unwrap(4000)
```
