////  Postgres column types for use with `gloo/migration`.
////
////  Build columns with `pg.column(name, type)` then pass them to the
////  migration DSL.  The modifier functions (`not_null`, `primary_key`,
////  `unique`, `default`) are re-exported here so callers only need to
////  import `gloo/pg`.

import gleam/int
import gloo/migration.{type Column}

pub type PgColumnType {
  Text
  VarChar(Int)
  Integer
  BigInt
  SmallInt
  Boolean
  Timestamp
  TimestampTz
  Date
  Time
  Uuid
  Numeric(precision: Int, scale: Int)
  JsonB
  ByteA
  Serial
  BigSerial
  Real
  DoublePrecision
}

/// Render a Postgres column type to its DDL SQL string.
pub fn type_sql(t: PgColumnType) -> String {
  case t {
    Text -> "TEXT"
    VarChar(n) -> "VARCHAR(" <> int.to_string(n) <> ")"
    Integer -> "INTEGER"
    BigInt -> "BIGINT"
    SmallInt -> "SMALLINT"
    Boolean -> "BOOLEAN"
    Timestamp -> "TIMESTAMP"
    TimestampTz -> "TIMESTAMPTZ"
    Date -> "DATE"
    Time -> "TIME"
    Uuid -> "UUID"
    Numeric(p, s) ->
      "NUMERIC(" <> int.to_string(p) <> ", " <> int.to_string(s) <> ")"
    JsonB -> "JSONB"
    ByteA -> "BYTEA"
    Serial -> "SERIAL"
    BigSerial -> "BIGSERIAL"
    Real -> "REAL"
    DoublePrecision -> "DOUBLE PRECISION"
  }
}

/// Create a Postgres-typed column.  Compile error if you pass a
/// `gloo/sqlite.SqColumnType` — they are different types.
pub fn column(name: String, t: PgColumnType) -> Column {
  migration.column(name, type_sql(t))
}

pub fn not_null(col: Column) -> Column {
  migration.not_null(col)
}

pub fn primary_key(col: Column) -> Column {
  migration.primary_key(col)
}

pub fn unique(col: Column) -> Column {
  migration.unique(col)
}

pub fn default(col: Column, expr: String) -> Column {
  migration.default(col, expr)
}
