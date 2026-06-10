////  Postgres adapter.  Wraps the `pog` connection pool.
////
////  ```gleam
////  postgres.default_config()
////  |> postgres.database("myapp_dev")
////  |> postgres.user("postgres")
////  |> postgres.start()
////  // -> Result(Repo, actor.StartError)
////  ```

import gleam/erlang/process
import gleam/otp/actor
import gleam/option.{type Option, None}
import gloo/adapter.{Adapter, PgConnection, postgres_placeholder, postgres_quote}
import gloo/repo
import gloo/telemetry
import pog

pub type Config {
  Config(
    host: String,
    database: String,
    user: String,
    password: Option(String),
    pool_size: Int,
  )
}

pub fn default_config() -> Config {
  Config(
    host: "127.0.0.1",
    database: "postgres",
    user: "postgres",
    password: None,
    pool_size: 10,
  )
}

pub fn host(config: Config, host: String) -> Config {
  Config(..config, host:)
}

pub fn database(config: Config, database: String) -> Config {
  Config(..config, database:)
}

pub fn user(config: Config, user: String) -> Config {
  Config(..config, user:)
}

pub fn password(config: Config, password: Option(String)) -> Config {
  Config(..config, password:)
}

pub fn pool_size(config: Config, pool_size: Int) -> Config {
  Config(..config, pool_size:)
}

pub fn start(config: Config) -> Result(repo.Repo, actor.StartError) {
  let pool_name = process.new_name(prefix: "gloo_pg")
  let pog_config =
    pog.default_config(pool_name)
    |> pog.host(config.host)
    |> pog.database(config.database)
    |> pog.user(config.user)
    |> pog.password(config.password)
    |> pog.pool_size(config.pool_size)

  case pog.start(pog_config) {
    Ok(actor.Started(pid, conn)) -> {
      let pg_adapter =
        Adapter(
          name: "postgres",
          connection: PgConnection(conn:, pid:),
          quote_identifier: postgres_quote,
          placeholder: postgres_placeholder,
          savepoint_depth: 0,
          telemetry: telemetry.disabled(),
        )
      Ok(repo.from_adapter(pg_adapter))
    }
    Error(e) -> Error(e)
  }
}
