////  Adapter — the sole DB-specific layer (V12).
////
////  `execute_query` and `run_transaction` dispatch to the correct backend
////  based on the `DbConnection` variant.  `repo`, `query`, `sql`, and
////  `validate` modules never import pog or sqlight directly.

import gleam/dynamic/decode.{type Dynamic}
import gleam/erlang/atom
import gleam/erlang/process
import gleam/list
import gleam/option.{None}
import gleam/result
import gleam/string
import gloo/error.{type GlooError}
import gloo/telemetry.{type Telemetry}
import gloo/value.{type GlooValue}
import pog
import sqlight

pub type DbConnection {
  PgConnection(conn: pog.Connection, pid: process.Pid)
  SqConnection(sqlight.Connection)
}

pub type ExecuteResult {
  ExecuteResult(rows: List(Dynamic), count: Int)
}

pub type Adapter {
  Adapter(
    name: String,
    connection: DbConnection,
    quote_identifier: fn(String) -> String,
    placeholder: fn(Int) -> String,
    savepoint_depth: Int,
    telemetry: Telemetry,
  )
}

// ── public helpers ─────────────────────────────────────────────────────────

pub fn postgres_quote(identifier: String) -> String {
  "\"" <> identifier <> "\""
}

pub fn postgres_placeholder(n: Int) -> String {
  "$" <> int_to_string(n)
}

pub fn sqlite_quote(identifier: String) -> String {
  "\"" <> identifier <> "\""
}

/// SQLite uses `?` — parameters are bound positionally.
/// The sql/query modules always produce `$N`; we convert at execution time.
pub fn sqlite_placeholder(_n: Int) -> String {
  "?"
}

// ── execution dispatch ─────────────────────────────────────────────────────

pub fn execute_query(
  adapter: Adapter,
  sql: String,
  params: List(GlooValue),
) -> Result(ExecuteResult, GlooError) {
  case adapter.connection {
    PgConnection(conn:, ..) -> pg_execute(conn, sql, params)
    SqConnection(conn) -> sq_execute(conn, sql_to_sqlite(sql), params)
  }
}

/// V5/V6: run a top-level transaction (savepoint_depth == 0).
/// Ok → commit; Error → rollback.
pub fn run_transaction(
  adapter: Adapter,
  callback: fn(Adapter) -> Result(a, String),
) -> Result(a, GlooError) {
  case adapter.connection {
    PgConnection(conn:, pid:) ->
      pog.transaction(conn, fn(tx_conn) {
        let tx_adapter =
          Adapter(
            ..adapter,
            connection: PgConnection(conn: tx_conn, pid:),
            savepoint_depth: 1,
          )
        callback(tx_adapter)
      })
      |> result.map_error(fn(e) {
        case e {
          pog.TransactionQueryError(qe) -> error.from_pog(qe)
          pog.TransactionRolledBack(msg) -> error.DbError(msg)
        }
      })
    SqConnection(conn) -> {
      case sqlight.exec("BEGIN", conn) {
        Error(e) -> Error(error.DbError(e.message))
        Ok(_) -> {
          let tx_adapter = Adapter(..adapter, savepoint_depth: 1)
          case callback(tx_adapter) {
            Ok(v) ->
              case sqlight.exec("COMMIT", conn) {
                Ok(_) -> Ok(v)
                Error(e) -> Error(error.DbError(e.message))
              }
            Error(msg) -> {
              let _ = sqlight.exec("ROLLBACK", conn)
              Error(error.DbError(msg))
            }
          }
        }
      }
    }
  }
}

// ── Postgres execution ─────────────────────────────────────────────────────

fn pg_execute(
  conn: pog.Connection,
  sql: String,
  params: List(GlooValue),
) -> Result(ExecuteResult, GlooError) {
  let pg_params = list.map(params, encode_pg_value)
  let result =
    pog.query(sql)
    |> list.fold(pg_params, _, pog.parameter)
    |> pog.returning(decode.dynamic)
    |> pog.execute(on: conn)
  case result {
    Ok(r) -> Ok(ExecuteResult(rows: r.rows, count: r.count))
    Error(e) -> Error(error.from_pog(e))
  }
}

fn encode_pg_value(v: GlooValue) -> pog.Value {
  case v {
    value.GString(s) -> pog.text(s)
    value.GInt(n) -> pog.int(n)
    value.GFloat(f) -> pog.float(f)
    value.GBool(b) -> pog.bool(b)
    value.GBitArray(ba) -> pog.bytea(ba)
    value.GTimestamp(ts) -> pog.timestamp(ts)
    value.GNull -> pog.nullable(fn(x) { x }, None)
    value.GArray(items) -> pog.array(encode_pg_value, items)
    value.GStringArray(items) -> pog.array(pog.text, items)
    value.GIntArray(items) -> pog.array(pog.int, items)
  }
}

// ── SQLite execution ───────────────────────────────────────────────────────

fn sq_execute(
  conn: sqlight.Connection,
  sql: String,
  params: List(GlooValue),
) -> Result(ExecuteResult, GlooError) {
  let sq_params = list.filter_map(params, encode_sq_value)
  case list.length(sq_params) == list.length(params) {
    False -> Error(error.DbError("unsupported value type for SQLite"))
    True ->
      case sqlight.query(sql, on: conn, with: sq_params, expecting: decode.dynamic) {
        Ok(rows) -> Ok(ExecuteResult(rows:, count: list.length(rows)))
        Error(e) -> Error(error.from_sqlight(e))
      }
  }
}

fn encode_sq_value(v: GlooValue) -> Result(sqlight.Value, Nil) {
  case v {
    value.GString(s) -> Ok(sqlight.text(s))
    value.GInt(n) -> Ok(sqlight.int(n))
    value.GFloat(f) -> Ok(sqlight.float(f))
    value.GBool(b) -> Ok(sqlight.bool(b))
    value.GBitArray(ba) -> Ok(sqlight.blob(ba))
    value.GTimestamp(_) -> Error(Nil)
    value.GNull -> Ok(sqlight.null())
    value.GArray(_) -> Error(Nil)
    value.GStringArray(_) -> Error(Nil)
    value.GIntArray(_) -> Error(Nil)
  }
}

/// Converts `$N` placeholders to `?` for SQLite's positional binding.
fn sql_to_sqlite(sql: String) -> String {
  replace_pg_placeholders(sql, 1)
}

fn replace_pg_placeholders(sql: String, n: Int) -> String {
  let placeholder = "$" <> int_to_string(n)
  case string.contains(sql, placeholder) {
    False -> sql
    True ->
      replace_pg_placeholders(string.replace(sql, placeholder, "?"), n + 1)
  }
}

/// Close the underlying connection.  Stops the pog pool process for Postgres,
/// releasing all held connections.  Idempotent: calling twice is safe.
pub fn close(adapter: Adapter) -> Result(Nil, String) {
  case adapter.connection {
    PgConnection(pid:, ..) -> {
      let _ = stop_process(pid, atom.create("normal"))
      Ok(Nil)
    }
    SqConnection(conn) ->
      sqlight.close(conn)
      |> result.map_error(fn(e: sqlight.Error) { e.message })
  }
}

@external(erlang, "erlang", "exit")
fn stop_process(pid: process.Pid, reason: atom.Atom) -> Bool

@external(erlang, "erlang", "integer_to_binary")
fn int_to_string(n: Int) -> String
