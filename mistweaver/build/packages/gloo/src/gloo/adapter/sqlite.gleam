////  SQLite adapter.  Wraps `sqlight`.
////
////  ```gleam
////  use r <- result.try(sqlite.start(sqlite.memory()))
////  use r <- result.try(sqlite.start(sqlite.file("mydb.sqlite3")))
////  // ... use r ...
////  repo.close(r)
////  ```

import gloo/adapter.{Adapter, SqConnection, sqlite_placeholder, sqlite_quote}
import gloo/repo
import gloo/telemetry
import sqlight

pub type Config {
  Config(path: String)
}

pub fn memory() -> Config {
  Config(path: ":memory:")
}

pub fn file(path: String) -> Config {
  Config(path:)
}

/// Open a SQLite connection and return a Repo.
/// Call `repo.close(r)` when done.
pub fn start(config: Config) -> Result(repo.Repo, String) {
  case sqlight.open(config.path) {
    Ok(conn) -> {
      let sq_adapter =
        Adapter(
          name: "sqlite",
          connection: SqConnection(conn),
          quote_identifier: sqlite_quote,
          placeholder: sqlite_placeholder,
          savepoint_depth: 0,
          telemetry: telemetry.disabled(),
        )
      Ok(repo.from_adapter(sq_adapter))
    }
    Error(e) -> Error(e.message)
  }
}
