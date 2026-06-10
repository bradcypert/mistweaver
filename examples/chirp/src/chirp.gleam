import gleam/erlang/process
import gleam/int
import gleam/option.{None}
import gloo/adapter/sqlite
import gloo/runner
import logging
import mistweaver
import chirp/migrations
import chirp/router as chirp_router

const session_secret = "chirp-dev-secret-change-in-production"

const port = 4000

pub fn main() {
  logging.configure()

  let assert Ok(repo) = sqlite.start(sqlite.file("chirp.sqlite3"))

  let assert Ok(_) = runner.run(repo, migrations.all(), runner.Up, None)

  let router = chirp_router.build(repo, session_secret)

  let assert Ok(_) =
    mistweaver.new_config()
    |> mistweaver.port(port)
    |> mistweaver.start(router)

  logging.log(
    logging.Info,
    "Chirp running at http://localhost:" <> int.to_string(port),
  )
  process.sleep_forever()
}
