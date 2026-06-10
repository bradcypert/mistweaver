////  Execute queries against a database connection pool.
////
////  Functions accept either a `Query(t)` (from the query builder), a `Sql(t)`
////  (from the sql module), or a plain SQL string + params list.
////
////  Transaction semantics: `Ok` commits, `Error` rolls back.  Nested
////  `repo.transaction` calls automatically become savepoints.

import gleam/dynamic/decode.{type Decoder}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gloo/adapter.{type Adapter, Adapter}
import gloo/error.{type GlooError}
import gloo/query.{type Query}
import gloo/sql.{type Sql}
import gloo/telemetry.{type Telemetry}
import gloo/value.{type GlooValue}

pub opaque type Repo {
  Repo(adapter: Adapter)
}

pub fn from_adapter(adapter: Adapter) -> Repo {
  Repo(adapter:)
}

pub fn adapter_name(repo: Repo) -> String {
  let Repo(adapter:) = repo
  adapter.name
}

pub fn with_telemetry(repo: Repo, t: Telemetry) -> Repo {
  let Repo(adapter:) = repo
  Repo(Adapter(..adapter, telemetry: t))
}

pub fn all(
  repo: Repo,
  sql: String,
  params: List(GlooValue),
  decoder: Decoder(t),
) -> Result(List(t), GlooError) {
  let Repo(adapter:) = repo
  telemetry.emit(
    adapter.telemetry,
    telemetry.QueryStart(sql:, params_count: list.length(params)),
  )
  case adapter.execute_query(adapter, sql, params) {
    Ok(adapter.ExecuteResult(rows:, count:)) -> {
      telemetry.emit(
        adapter.telemetry,
        telemetry.QueryEnd(sql:, duration_ms: 0, rows: count),
      )
      list.try_map(rows, fn(row) {
        decode.run(row, decoder)
        |> result.map_error(fn(errs) {
          case errs {
            [decode.DecodeError(expected:, found:, ..), ..] ->
              error.DbError("decode error: expected " <> expected <> ", got " <> found)
            [] -> error.DbError("decode error")
          }
        })
      })
    }
    Error(e) -> {
      telemetry.emit(
        adapter.telemetry,
        telemetry.QueryError(sql:, reason: error.to_string(e)),
      )
      Error(e)
    }
  }
}

pub fn one(
  repo: Repo,
  sql: String,
  params: List(GlooValue),
  decoder: Decoder(t),
) -> Result(t, GlooError) {
  use rows <- result.try(all(repo, sql, params, decoder))
  one_from_rows(rows)
}

pub fn maybe_one(
  repo: Repo,
  sql: String,
  params: List(GlooValue),
  decoder: Decoder(t),
) -> Result(Option(t), GlooError) {
  use rows <- result.try(all(repo, sql, params, decoder))
  maybe_one_from_rows(rows)
}

pub fn execute(
  repo: Repo,
  sql: String,
  params: List(GlooValue),
) -> Result(Int, GlooError) {
  let Repo(adapter:) = repo
  telemetry.emit(
    adapter.telemetry,
    telemetry.QueryStart(sql:, params_count: list.length(params)),
  )
  case adapter.execute_query(adapter, sql, params) {
    Ok(adapter.ExecuteResult(count:, ..)) -> {
      telemetry.emit(
        adapter.telemetry,
        telemetry.QueryEnd(sql:, duration_ms: 0, rows: count),
      )
      Ok(count)
    }
    Error(e) -> {
      telemetry.emit(
        adapter.telemetry,
        telemetry.QueryError(sql:, reason: error.to_string(e)),
      )
      Error(e)
    }
  }
}

/// V5: Ok → commit, Error → rollback.
/// V6: nested calls become savepoints (savepoint_depth > 0).
pub fn transaction(
  repo: Repo,
  callback: fn(Repo) -> Result(t, GlooError),
) -> Result(t, GlooError) {
  let Repo(adapter:) = repo
  case adapter.savepoint_depth {
    0 ->
      adapter.run_transaction(adapter, fn(tx_adapter) {
        callback(Repo(tx_adapter)) |> result.map_error(error.to_string)
      })
    depth -> {
      let sp = "sp_" <> int_to_string(depth)
      use _ <- result.try(run_sql(repo, "SAVEPOINT " <> sp))
      case callback(Repo(Adapter(..adapter, savepoint_depth: depth + 1))) {
        Ok(v) -> {
          use _ <- result.try(run_sql(repo, "RELEASE SAVEPOINT " <> sp))
          Ok(v)
        }
        Error(e) -> {
          use _ <- result.try(
            run_sql(repo, "ROLLBACK TO SAVEPOINT " <> sp),
          )
          Error(e)
        }
      }
    }
  }
}

fn run_sql(repo: Repo, sql: String) -> Result(Nil, GlooError) {
  execute(repo, sql, []) |> result.map(fn(_) { Nil })
}

@external(erlang, "erlang", "integer_to_binary")
fn int_to_string(n: Int) -> String

// ── pure row-count helpers (also used in tests) ───────────────────────────

pub fn one_from_rows(rows: List(t)) -> Result(t, GlooError) {
  case rows {
    [row] -> Ok(row)
    [] -> Error(error.NoResultError)
    _ -> Error(error.TooManyResultsError(list.length(rows)))
  }
}

pub fn maybe_one_from_rows(rows: List(t)) -> Result(Option(t), GlooError) {
  case rows {
    [] -> Ok(None)
    [row] -> Ok(Some(row))
    _ -> Error(error.TooManyResultsError(list.length(rows)))
  }
}

// ── Query-builder overloads ────────────────────────────────────────────────

pub fn query_all(
  repo: Repo,
  q: Query(t),
) -> Result(List(t), GlooError) {
  let #(sql, params) = query.to_sql(q)
  all(repo, sql, params, query.decoder(q))
}

pub fn query_one(
  repo: Repo,
  q: Query(t),
) -> Result(t, GlooError) {
  let #(sql, params) = query.to_sql(q)
  one(repo, sql, params, query.decoder(q))
}

pub fn query_maybe_one(
  repo: Repo,
  q: Query(t),
) -> Result(Option(t), GlooError) {
  let #(sql, params) = query.to_sql(q)
  maybe_one(repo, sql, params, query.decoder(q))
}

pub fn query_execute(
  repo: Repo,
  q: Query(t),
) -> Result(Int, GlooError) {
  let #(sql, params) = query.to_sql(q)
  execute(repo, sql, params)
}

// ── Sql-module overloads ───────────────────────────────────────────────────

pub fn sql_all(repo: Repo, s: Sql(t)) -> Result(List(t), GlooError) {
  let #(statement, parameters, decoder) = sql.to_parts(s)
  all(repo, statement, parameters, decoder)
}

pub fn sql_one(repo: Repo, s: Sql(t)) -> Result(t, GlooError) {
  let #(statement, parameters, decoder) = sql.to_parts(s)
  one(repo, statement, parameters, decoder)
}

pub fn sql_maybe_one(
  repo: Repo,
  s: Sql(t),
) -> Result(Option(t), GlooError) {
  let #(statement, parameters, decoder) = sql.to_parts(s)
  maybe_one(repo, statement, parameters, decoder)
}

pub fn sql_execute(repo: Repo, s: Sql(t)) -> Result(Int, GlooError) {
  let #(statement, parameters, _) = sql.to_parts(s)
  execute(repo, statement, parameters)
}

/// Close the underlying DB connection.  For Postgres this stops the pool
/// process and releases all held connections.  For SQLite this closes the file.
/// Idempotent: calling twice is safe.
pub fn close(repo: Repo) -> Result(Nil, String) {
  let Repo(adapter:) = repo
  adapter.close(adapter)
}
