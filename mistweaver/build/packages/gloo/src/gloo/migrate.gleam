////  Migration CLI entry point.  Call `migrate.main_with_migrations(repo, migrations)`
////  from your `main` function to expose the `migrate` subcommand.
////
////  Subcommands: `up [--step N]`, `down [--step N]`, `status`, `gen <name>`.

import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gloo/migration.{type Migration}
import gloo/repo.{type Repo}
import gloo/runner

/// Entry point for the migration CLI.
/// Call this from your app's main function, passing the Repo and your migration list.
///
/// Usage:
///   gleam run -m myapp/db -- migrate up
///   gleam run -m myapp/db -- migrate up --step 2
///   gleam run -m myapp/db -- migrate down --step 1
///   gleam run -m myapp/db -- migrate status
///   gleam run -m myapp/db -- migrate gen create_posts
pub fn main_with_migrations(r: Repo, migrations: List(Migration)) -> Nil {
  let args = start_arguments()
  case parse_args(args) {
    Error(msg) -> {
      io.println("Error: " <> msg)
      io.println(usage())
    }
    Ok(cmd) -> run_command(r, migrations, cmd)
  }
}

// ── command types ──────────────────────────────────────────────────────────

type Command {
  MigrateUp(step: option.Option(Int))
  MigrateDown(step: option.Option(Int))
  Status
  Gen(name: String)
}

// ── arg parsing ────────────────────────────────────────────────────────────

fn parse_args(args: List(String)) -> Result(Command, String) {
  case args {
    ["migrate", "up", ..rest] -> Ok(MigrateUp(parse_step(rest)))
    ["migrate", "down", ..rest] -> Ok(MigrateDown(parse_step(rest)))
    ["migrate", "status"] -> Ok(Status)
    ["migrate", "gen", name] -> Ok(Gen(name))
    _ -> Error("unknown command")
  }
}

fn parse_step(args: List(String)) -> option.Option(Int) {
  case args {
    ["--step", n, ..] ->
      case int.parse(n) {
        Ok(v) -> Some(v)
        Error(_) -> None
      }
    _ -> None
  }
}

// ── command execution ──────────────────────────────────────────────────────

fn run_command(r: Repo, migrations: List(Migration), cmd: Command) -> Nil {
  case cmd {
    MigrateUp(step:) -> {
      case runner.run(r, migrations, runner.Up, step) {
        Ok(0) -> io.println("Already up to date.")
        Ok(n) -> io.println("Applied " <> int.to_string(n) <> " migration(s).")
        Error(e) -> io.println("Migration failed: " <> runner_error_msg(e))
      }
    }

    MigrateDown(step:) -> {
      let effective_step = option.unwrap(step, 1)
      case runner.run(r, migrations, runner.Down, Some(effective_step)) {
        Ok(0) -> io.println("Nothing to roll back.")
        Ok(n) ->
          io.println("Rolled back " <> int.to_string(n) <> " migration(s).")
        Error(e) -> io.println("Rollback failed: " <> runner_error_msg(e))
      }
    }

    Status -> {
      case runner.applied_versions(r) {
        Error(e) -> io.println("Error: " <> runner_error_msg(e))
        Ok(applied) -> {
          io.println("Migration status:")
          list.each(migrations, fn(m) {
            let mark = case list.contains(applied, m.version) {
              True -> "[x]"
              False -> "[ ]"
            }
            io.println(
              mark
              <> " "
              <> int.to_string(m.version)
              <> " "
              <> m.name,
            )
          })
        }
      }
    }

    Gen(name:) -> gen_migration(migrations, name)
  }
}

fn gen_migration(existing: List(Migration), name: String) -> Nil {
  let version = case
    list.sort(existing, fn(a, b) { int.compare(b.version, a.version) })
  {
    [latest, ..] -> latest.version + 1
    [] -> 1
  }
  let snake_name =
    string.lowercase(name)
    |> string.replace(" ", "_")
  let content =
    "import gloo/migration.{type Migration}\n\npub fn migration() -> Migration {\n  migration.execute_sql(\n    version: "
    <> int.to_string(version)
    <> ",\n    name: \""
    <> snake_name
    <> "\",\n    up: \"\"\"\n    -- write your SQL here\n    \"\"\",\n    down: \"-- write your rollback SQL here\",\n  )\n}\n"
  io.println("Generated migration " <> int.to_string(version) <> "_" <> snake_name)
  io.println("Content:")
  io.println(content)
}

@external(erlang, "migrate_ffi", "start_arguments")
fn start_arguments() -> List(String)

fn usage() -> String {
  "Usage: gleam run -m <module> -- migrate <command>\n  up [--step N]    apply pending migrations\n  down [--step N]  roll back migrations (default: 1)\n  status           show migration status\n  gen <name>       generate a new migration"
}

fn runner_error_msg(e: runner.RunnerError) -> String {
  case e {
    runner.DbError(msg) -> msg
    runner.MigrationFailed(version: v, name: n, reason: r) ->
      "migration " <> int.to_string(v) <> " (" <> n <> "): " <> r
  }
}
