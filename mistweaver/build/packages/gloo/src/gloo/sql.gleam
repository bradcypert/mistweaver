////  Typed raw SQL builder.  Use when a query spans multiple tables or needs
////  features the query builder does not cover.
////
////  ```gleam
////  sql.query("SELECT * FROM users WHERE id = $1")
////  |> sql.param(sql.int(id))
////  |> sql.returns(user_decoder)
////  |> repo.sql_one(r, _)
////  ```
////
////  Value constructors: `string`, `int`, `bool`, `time`, `uuid`, `nullable`.
////  A `Sql(t)` value is inert until passed to a `repo.sql_*` function.

import birl
import gleam/dynamic/decode.{type Decoder}
import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/string
import gleam/time/timestamp
import gloo/value.{type GlooValue}

// V2: Sql(t) is inert — never executes itself; repo functions run it.

pub opaque type Sql(t) {
  Sql(
    statement: String,
    parameters: List(GlooValue),
    decoder: Decoder(t),
    param_count: Int,
  )
}

// ── value constructors ─────────────────────────────────────────────────────

pub fn string(v: String) -> GlooValue {
  value.GString(v)
}

pub fn int(v: Int) -> GlooValue {
  value.GInt(v)
}

pub fn bool(v: Bool) -> GlooValue {
  value.GBool(v)
}

pub fn time(v: birl.Time) -> GlooValue {
  let micros = birl.to_unix_micro(v)
  let seconds = micros / 1_000_000
  let nanoseconds = { micros % 1_000_000 } * 1000
  value.GTimestamp(timestamp.from_unix_seconds_and_nanoseconds(seconds, nanoseconds))
}

pub fn uuid(v: String) -> GlooValue {
  value.GString(v)
}

pub fn nullable(encoder: fn(a) -> GlooValue, v: Option(a)) -> GlooValue {
  value.nullable(encoder, v)
}

// ── query builders ─────────────────────────────────────────────────────────

pub fn query(statement: String) -> Sql(Nil) {
  Sql(
    statement:,
    parameters: [],
    decoder: decode.success(Nil),
    param_count: 0,
  )
}

pub fn param(sql: Sql(t), v: GlooValue) -> Sql(t) {
  Sql(
    ..sql,
    parameters: list.append(sql.parameters, [v]),
    param_count: sql.param_count + 1,
  )
}

pub fn params(sql: Sql(t), values: List(GlooValue)) -> Sql(t) {
  list.fold(values, sql, param)
}

pub fn returns(sql: Sql(t), decoder: Decoder(u)) -> Sql(u) {
  Sql(
    statement: sql.statement,
    parameters: sql.parameters,
    decoder:,
    param_count: sql.param_count,
  )
}

/// Generates `($n, $n+1, ...)` for use in an IN clause.
/// Returns the placeholder fragment and the updated Sql with params added.
pub fn in_clause(
  sql: Sql(t),
  values: List(GlooValue),
) -> #(Sql(t), String) {
  let start = sql.param_count + 1
  let placeholders =
    list.index_map(values, fn(_, i) { "$" <> int.to_string(start + i) })
    |> string.join(", ")
  let clause = "(" <> placeholders <> ")"
  #(params(sql, values), clause)
}

/// Encodes a list as a Postgres array for use with UNNEST (Postgres-only).
pub fn unnest(encoder: fn(a) -> GlooValue, values: List(a)) -> GlooValue {
  value.GArray(list.map(values, encoder))
}

// ── accessors (used by repo) ───────────────────────────────────────────────

pub fn to_parts(sql: Sql(t)) -> #(String, List(GlooValue), Decoder(t)) {
  #(sql.statement, sql.parameters, sql.decoder)
}
