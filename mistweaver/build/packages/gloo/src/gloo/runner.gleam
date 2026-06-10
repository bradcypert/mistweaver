////  Low-level migration runner.  `runner.run` applies or rolls back a list of
////  migrations, skipping versions already recorded in `schema_migrations`.
////  Each migration runs in its own transaction.  Normally you call
////  `migrate.main_with_migrations` instead of using this directly.

import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gloo/error
import gloo/migration.{type Migration}
import gloo/repo.{type Repo}
import gloo/value

pub type Direction {
  Up
  Down
}

pub type RunnerError {
  DbError(String)
  MigrationFailed(version: Int, name: String, reason: String)
}

// ── schema_migrations DDL ──────────────────────────────────────────────────

// Postgres: TIMESTAMPTZ preserves timezone; NOW() returns a proper timestamptz.
const create_schema_migrations_pg = "
CREATE TABLE IF NOT EXISTS schema_migrations (
  version    INTEGER PRIMARY KEY,
  name       TEXT NOT NULL,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
)
"

// SQLite: TEXT with CURRENT_TIMESTAMP is the portable equivalent.
// NOW() is not a SQLite built-in; TIMESTAMPTZ has no meaning there.
const create_schema_migrations_sq = "
CREATE TABLE IF NOT EXISTS schema_migrations (
  version    INTEGER PRIMARY KEY,
  name       TEXT NOT NULL,
  applied_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
)
"

// ── core runner ────────────────────────────────────────────────────────────

/// Run pending migrations in the given direction.
/// V8: each migration runs in its own transaction.
/// V9: schema_migrations tracks applied versions; already-applied are skipped.
pub fn run(
  r: Repo,
  migrations: List(Migration),
  direction: Direction,
  step: option.Option(Int),
) -> Result(Int, RunnerError) {
  use _ <- result.try(ensure_schema_migrations(r))
  use applied <- result.try(fetch_applied_versions(r))

  let to_run = case direction {
    Up ->
      list.filter(migrations, fn(m) { !list.contains(applied, m.version) })
      |> list.sort(fn(a, b) { int.compare(a.version, b.version) })
    Down ->
      list.filter(migrations, fn(m) { list.contains(applied, m.version) })
      |> list.sort(fn(a, b) { int.compare(b.version, a.version) })
  }

  let capped = case step {
    None -> to_run
    Some(n) -> list.take(to_run, n)
  }

  list.try_fold(capped, 0, fn(count, m) {
    use _ <- result.try(run_one(r, m, direction))
    Ok(count + 1)
  })
}

/// V9: return list of applied migration versions in ascending order.
pub fn applied_versions(r: Repo) -> Result(List(Int), RunnerError) {
  use _ <- result.try(ensure_schema_migrations(r))
  fetch_applied_versions(r)
}

// ── private helpers ────────────────────────────────────────────────────────

fn ensure_schema_migrations(r: Repo) -> Result(Nil, RunnerError) {
  let ddl = case repo.adapter_name(r) {
    "postgres" -> create_schema_migrations_pg
    _ -> create_schema_migrations_sq
  }
  repo.execute(r, ddl, [])
  |> result.map(fn(_) { Nil })
  |> result.map_error(fn(e) { DbError(error.to_string(e)) })
}

fn fetch_applied_versions(r: Repo) -> Result(List(Int), RunnerError) {
  let decoder = {
    use v <- decode.field(0, decode.int)
    decode.success(v)
  }
  repo.all(
    r,
    "SELECT version FROM schema_migrations ORDER BY version ASC",
    [],
    decoder,
  )
  |> result.map_error(fn(e) { DbError(error.to_string(e)) })
}

// V8: each migration runs in its own transaction
fn run_one(r: Repo, m: Migration, direction: Direction) -> Result(Nil, RunnerError) {
  let sql = case direction {
    Up -> Some(m.up)
    Down -> m.down
  }
  case sql {
    None -> Ok(Nil)
    Some(statement) -> {
      repo.transaction(r, fn(tx) {
        let stmts =
          string.split(statement, ";")
          |> list.map(string.trim)
          |> list.filter(fn(s) { s != "" })
        use _ <- result.try(
          list.try_fold(stmts, Nil, fn(_, stmt) {
            repo.execute(tx, stmt, [])
            |> result.map(fn(_) { Nil })
          }),
        )
        case direction {
          Up ->
            repo.execute(
              tx,
              "INSERT INTO schema_migrations (version, name) VALUES ($1, $2) ON CONFLICT (version) DO NOTHING",
              [value.GInt(m.version), value.GString(m.name)],
            )
          Down ->
            repo.execute(
              tx,
              "DELETE FROM schema_migrations WHERE version = $1",
              [value.GInt(m.version)],
            )
        }
        |> result.map(fn(_) { Nil })
      })
      |> result.map_error(fn(e) {
        MigrationFailed(
          version: m.version,
          name: m.name,
          reason: error.to_string(e),
        )
      })
    }
  }
}
