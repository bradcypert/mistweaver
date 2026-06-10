////  SQLite column types for use with `gloo/migration`.
////
////  Build columns with `sqlite.column(name, type)` then pass them to the
////  migration DSL.  Autoincrement is achieved by applying `primary_key` to
////  an `Integer` column — SQLite's rowid mechanism handles the rest.
////
////  Passing a `SqColumnType` to `gloo/pg.column` (or vice versa) is a
////  compile error because the types are distinct.

import gloo/migration.{type Column}

pub type SqColumnType {
  Integer
  Text
  Real
  Blob
}

/// Render a SQLite column type to its DDL SQL string.
pub fn type_sql(t: SqColumnType) -> String {
  case t {
    Integer -> "INTEGER"
    Text -> "TEXT"
    Real -> "REAL"
    Blob -> "BLOB"
  }
}

/// Create a SQLite-typed column.  Compile error if you pass a
/// `gloo/pg.PgColumnType` — they are different types.
pub fn column(name: String, t: SqColumnType) -> Column {
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
