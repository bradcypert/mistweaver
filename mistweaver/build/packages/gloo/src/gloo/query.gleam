////  Single-table query builder.  Use `query.from(table)` to start, then pipe
////  through `where`, `order_by`, `limit`, `offset`, `insert`, `update`, or
////  `delete`.  A `Query(t)` is an inert value — it only executes when passed
////  to a `repo` function (`repo.query_all`, `repo.query_one`, etc.).
////
////  Available predicates: `Eq`, `Neq`, `Gt`, `Gte`, `Lt`, `Lte`, `In`,
////  `Like`, `IsNull`, `IsNotNull`, `And`, `Or`, `Not`.

import gleam/dynamic/decode.{type Decoder}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import gloo/schema.{type Table}
import gloo/value.{type GlooValue}

// V2: Query is inert — holds SQL + params, never executes itself.
// V1: Single-table only; multi-table SQL goes through the sql module.

pub opaque type Query(t) {
  Query(table: String, op: Op, decoder: Decoder(t))
}

pub type Condition {
  Eq(column: String, value: GlooValue)
  Neq(column: String, value: GlooValue)
  Gt(column: String, value: GlooValue)
  Gte(column: String, value: GlooValue)
  Lt(column: String, value: GlooValue)
  Lte(column: String, value: GlooValue)
  In(column: String, values: List(GlooValue))
  Like(column: String, pattern: String)
  IsNull(column: String)
  IsNotNull(column: String)
  And(List(Condition))
  Or(List(Condition))
  Not(Condition)
}

pub type Direction {
  Asc
  Desc
}

type Op {
  Select(
    conditions: List(Condition),
    orders: List(#(String, Direction)),
    limit: Option(Int),
    offset: Option(Int),
  )
  Insert(
    columns: List(String),
    values: List(GlooValue),
    returning_cols: Option(List(String)),
  )
  Update(sets: List(#(String, GlooValue)), conditions: List(Condition))
  Delete(conditions: List(Condition))
}

// ── entry point ────────────────────────────────────────────────────────────

pub fn from(table: Table(t)) -> Query(t) {
  Query(
    table: table.name,
    op: Select(conditions: [], orders: [], limit: None, offset: None),
    decoder: table.decoder,
  )
}

// ── mutation ops ───────────────────────────────────────────────────────────

pub fn insert(
  _query: Query(t),
  table: Table(t),
  row: List(#(String, GlooValue)),
) -> Query(t) {
  let cols = list.map(row, fn(pair) { pair.0 })
  let vals = list.map(row, fn(pair) { pair.1 })
  Query(
    table: table.name,
    op: Insert(columns: cols, values: vals, returning_cols: None),
    decoder: table.decoder,
  )
}

pub fn update(
  query: Query(t),
  sets: List(#(String, GlooValue)),
) -> Query(t) {
  Query(..query, op: Update(sets:, conditions: []))
}

pub fn delete(query: Query(t)) -> Query(t) {
  Query(..query, op: Delete(conditions: []))
}

// ── select modifiers ───────────────────────────────────────────────────────

pub fn where(query: Query(t), condition: Condition) -> Query(t) {
  case query.op {
    Select(conditions:, orders:, limit:, offset:) ->
      Query(
        ..query,
        op: Select(
          conditions: list.append(conditions, [condition]),
          orders:,
          limit:,
          offset:,
        ),
      )
    Update(sets:, conditions:) ->
      Query(
        ..query,
        op: Update(
          sets:,
          conditions: list.append(conditions, [condition]),
        ),
      )
    Delete(conditions:) ->
      Query(
        ..query,
        op: Delete(conditions: list.append(conditions, [condition])),
      )
    Insert(..) -> query
  }
}

pub fn order_by(
  query: Query(t),
  column: String,
  direction: Direction,
) -> Query(t) {
  case query.op {
    Select(conditions:, orders:, limit:, offset:) ->
      Query(
        ..query,
        op: Select(
          conditions:,
          orders: list.append(orders, [#(column, direction)]),
          limit:,
          offset:,
        ),
      )
    _ -> query
  }
}

pub fn limit(query: Query(t), n: Int) -> Query(t) {
  case query.op {
    Select(conditions:, orders:, limit: _, offset:) ->
      Query(
        ..query,
        op: Select(conditions:, orders:, limit: Some(n), offset:),
      )
    _ -> query
  }
}

pub fn offset(query: Query(t), n: Int) -> Query(t) {
  case query.op {
    Select(conditions:, orders:, limit:, offset: _) ->
      Query(
        ..query,
        op: Select(conditions:, orders:, limit:, offset: Some(n)),
      )
    _ -> query
  }
}

pub fn returning(query: Query(t), decoder: Decoder(u)) -> Query(u) {
  Query(table: query.table, op: query.op, decoder:)
}

pub fn returning_columns(query: Query(t), cols: List(String)) -> Query(t) {
  case query.op {
    Insert(columns:, values:, returning_cols: _) ->
      Query(
        ..query,
        op: Insert(columns:, values:, returning_cols: Some(cols)),
      )
    _ -> query
  }
}

// ── SQL generation ─────────────────────────────────────────────────────────

pub fn to_sql(query: Query(t)) -> #(String, List(GlooValue)) {
  let table = "\"" <> query.table <> "\""
  case query.op {
    Insert(columns:, values:, returning_cols:) ->
      build_insert(table, columns, values, returning_cols)
    Select(conditions:, orders:, limit:, offset:) ->
      build_select(table, conditions, orders, limit, offset)
    Update(sets:, conditions:) -> build_update(table, sets, conditions)
    Delete(conditions:) -> build_delete(table, conditions)
  }
}

pub fn decoder(query: Query(t)) -> Decoder(t) {
  query.decoder
}

// ── SQL helpers ────────────────────────────────────────────────────────────

fn build_insert(
  table: String,
  columns: List(String),
  values: List(GlooValue),
  ret: Option(List(String)),
) -> #(String, List(GlooValue)) {
  let cols = string.join(columns, ", ")
  let placeholders =
    list.index_map(values, fn(_, i) { "$" <> int.to_string(i + 1) })
    |> string.join(", ")
  let ret_sql = case ret {
    None -> ""
    Some(cs) -> " RETURNING " <> string.join(cs, ", ")
  }
  let sql =
    "INSERT INTO "
    <> table
    <> " ("
    <> cols
    <> ") VALUES ("
    <> placeholders
    <> ")"
    <> ret_sql
  #(sql, values)
}

fn build_select(
  table: String,
  conditions: List(Condition),
  orders: List(#(String, Direction)),
  lim: Option(Int),
  off: Option(Int),
) -> #(String, List(GlooValue)) {
  let #(where_sql, params, _) = conditions_to_sql(conditions, 1)
  let order_sql = case orders {
    [] -> ""
    _ ->
      " ORDER BY "
      <> string.join(
        list.map(orders, fn(o) {
          o.0
          <> case o.1 {
            Asc -> " ASC"
            Desc -> " DESC"
          }
        }),
        ", ",
      )
  }
  let limit_sql = case lim {
    None -> ""
    Some(n) -> " LIMIT " <> int.to_string(n)
  }
  let offset_sql = case off {
    None -> ""
    Some(n) -> " OFFSET " <> int.to_string(n)
  }
  let sql =
    "SELECT * FROM "
    <> table
    <> where_sql
    <> order_sql
    <> limit_sql
    <> offset_sql
  #(sql, params)
}

fn build_update(
  table: String,
  sets: List(#(String, GlooValue)),
  conditions: List(Condition),
) -> #(String, List(GlooValue)) {
  let #(set_parts, set_vals) =
    list.index_map(sets, fn(pair, i) {
      #(pair.0 <> " = $" <> int.to_string(i + 1), pair.1)
    })
    |> list.unzip
  let set_sql = string.join(set_parts, ", ")
  let param_start = list.length(sets) + 1
  let #(where_sql, where_vals, _) = conditions_to_sql(conditions, param_start)
  let sql = "UPDATE " <> table <> " SET " <> set_sql <> where_sql
  #(sql, list.append(set_vals, where_vals))
}

fn build_delete(
  table: String,
  conditions: List(Condition),
) -> #(String, List(GlooValue)) {
  let #(where_sql, params, _) = conditions_to_sql(conditions, 1)
  #("DELETE FROM " <> table <> where_sql, params)
}

fn conditions_to_sql(
  conditions: List(Condition),
  start: Int,
) -> #(String, List(GlooValue), Int) {
  case conditions {
    [] -> #("", [], start)
    _ -> {
      let #(parts, params, next) =
        list.fold(conditions, #([], [], start), fn(acc, cond) {
          let #(parts, params, n) = acc
          let #(sql, vals, n2) = condition_to_sql(cond, n)
          #(list.append(parts, [sql]), list.append(params, vals), n2)
        })
      let where = " WHERE " <> string.join(parts, " AND ")
      #(where, params, next)
    }
  }
}

fn condition_to_sql(
  cond: Condition,
  n: Int,
) -> #(String, List(GlooValue), Int) {
  case cond {
    Eq(col, val) -> #(col <> " = $" <> int.to_string(n), [val], n + 1)
    Neq(col, val) -> #(col <> " != $" <> int.to_string(n), [val], n + 1)
    Gt(col, val) -> #(col <> " > $" <> int.to_string(n), [val], n + 1)
    Gte(col, val) -> #(col <> " >= $" <> int.to_string(n), [val], n + 1)
    Lt(col, val) -> #(col <> " < $" <> int.to_string(n), [val], n + 1)
    Lte(col, val) -> #(col <> " <= $" <> int.to_string(n), [val], n + 1)
    In(col, vals) -> {
      let placeholders =
        list.index_map(vals, fn(_, i) { "$" <> int.to_string(n + i) })
        |> string.join(", ")
      #(col <> " IN (" <> placeholders <> ")", vals, n + list.length(vals))
    }
    Like(col, pattern) ->
      #(col <> " LIKE $" <> int.to_string(n), [value.GString(pattern)], n + 1)
    IsNull(col) -> #(col <> " IS NULL", [], n)
    IsNotNull(col) -> #(col <> " IS NOT NULL", [], n)
    And(conds) -> {
      let #(parts, params, next) =
        list.fold(conds, #([], [], n), fn(acc, c) {
          let #(ps, vs, nn) = acc
          let #(s, vs2, nn2) = condition_to_sql(c, nn)
          #(list.append(ps, [s]), list.append(vs, vs2), nn2)
        })
      #("(" <> string.join(parts, " AND ") <> ")", params, next)
    }
    Or(conds) -> {
      let #(parts, params, next) =
        list.fold(conds, #([], [], n), fn(acc, c) {
          let #(ps, vs, nn) = acc
          let #(s, vs2, nn2) = condition_to_sql(c, nn)
          #(list.append(ps, [s]), list.append(vs, vs2), nn2)
        })
      #("(" <> string.join(parts, " OR ") <> ")", params, next)
    }
    Not(inner) -> {
      let #(s, vs, nn) = condition_to_sql(inner, n)
      #("NOT (" <> s <> ")", vs, nn)
    }
  }
}
