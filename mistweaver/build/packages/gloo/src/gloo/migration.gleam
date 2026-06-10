////  DDL migration DSL.  Each migration has a `version` (integer timestamp),
////  a `name`, an `up` SQL string, and an optional `down` SQL string.
////
////  Build columns using the DB-specific modules (`gloo/pg`, `gloo/sqlite`)
////  then pass them to `create_table`, `add_column`, etc.
////  `gloo/migration` itself carries no column-type knowledge.

import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

pub type Migration {
  Migration(version: Int, name: String, up: String, down: Option(String))
}

pub type Column {
  Column(
    name: String,
    type_sql: String,
    nullable: Bool,
    default: Option(String),
    primary_key: Bool,
    unique: Bool,
  )
}

// ── column builder ─────────────────────────────────────────────────────────

/// Low-level constructor that takes a raw SQL type string.
/// Prefer `gloo/pg.column` or `gloo/sqlite.column` for type-safe construction.
pub fn column(name: String, type_sql: String) -> Column {
  Column(name:, type_sql:, nullable: True, default: None, primary_key: False, unique: False)
}

pub fn not_null(col: Column) -> Column {
  Column(..col, nullable: False)
}

pub fn primary_key(col: Column) -> Column {
  Column(..col, primary_key: True, nullable: False)
}

pub fn unique(col: Column) -> Column {
  Column(..col, unique: True)
}

pub fn default(col: Column, expr: String) -> Column {
  Column(..col, default: Some(expr))
}

// ── migration constructors ─────────────────────────────────────────────────

pub fn new(version v: Int, name n: String, up u: String) -> Migration {
  Migration(version: v, name: n, up: u, down: None)
}

pub fn with_down(m: Migration, down: String) -> Migration {
  Migration(..m, down: Some(down))
}

pub fn execute_sql(
  version v: Int,
  name n: String,
  up up: String,
  down down: String,
) -> Migration {
  Migration(version: v, name: n, up: up, down: Some(down))
}

// ── DDL operations ─────────────────────────────────────────────────────────

pub fn create_table(
  version v: Int,
  name n: String,
  table table: String,
  columns cols: List(Column),
) -> Migration {
  let col_defs = list.map(cols, column_def) |> string.join(",\n  ")
  let up = "CREATE TABLE " <> table <> " (\n  " <> col_defs <> "\n)"
  Migration(version: v, name: n, up:, down: Some("DROP TABLE IF EXISTS " <> table))
}

pub fn drop_table(
  version v: Int,
  name n: String,
  table table: String,
) -> Migration {
  Migration(
    version: v,
    name: n,
    up: "DROP TABLE IF EXISTS " <> table,
    down: None,
  )
}

pub fn rename_table(
  version v: Int,
  name n: String,
  from from: String,
  to to: String,
) -> Migration {
  Migration(
    version: v,
    name: n,
    up: "ALTER TABLE " <> from <> " RENAME TO " <> to,
    down: Some("ALTER TABLE " <> to <> " RENAME TO " <> from),
  )
}

pub fn add_column(
  version v: Int,
  name n: String,
  table table: String,
  column col: Column,
) -> Migration {
  Migration(
    version: v,
    name: n,
    up: "ALTER TABLE "
      <> table
      <> " ADD COLUMN "
      <> column_def(col),
    down: Some(
      "ALTER TABLE " <> table <> " DROP COLUMN " <> col.name,
    ),
  )
}

pub fn drop_column(
  version v: Int,
  name n: String,
  table table: String,
  column_name col: String,
) -> Migration {
  Migration(
    version: v,
    name: n,
    up: "ALTER TABLE " <> table <> " DROP COLUMN " <> col,
    down: None,
  )
}

pub fn rename_column(
  version v: Int,
  name n: String,
  table table: String,
  from from: String,
  to to: String,
) -> Migration {
  Migration(
    version: v,
    name: n,
    up: "ALTER TABLE "
      <> table
      <> " RENAME COLUMN "
      <> from
      <> " TO "
      <> to,
    down: Some(
      "ALTER TABLE "
      <> table
      <> " RENAME COLUMN "
      <> to
      <> " TO "
      <> from,
    ),
  )
}

pub fn change_column(
  version v: Int,
  name n: String,
  table table: String,
  column_name col: String,
  new_type new_type: String,
) -> Migration {
  Migration(
    version: v,
    name: n,
    up: "ALTER TABLE " <> table <> " ALTER COLUMN " <> col <> " TYPE " <> new_type,
    down: None,
  )
}

pub fn create_index(
  version v: Int,
  name n: String,
  index index: String,
  table table: String,
  columns cols: List(String),
) -> Migration {
  Migration(
    version: v,
    name: n,
    up: "CREATE INDEX "
      <> index
      <> " ON "
      <> table
      <> " ("
      <> string.join(cols, ", ")
      <> ")",
    down: Some("DROP INDEX IF EXISTS " <> index),
  )
}

pub fn drop_index(
  version v: Int,
  name n: String,
  index index: String,
) -> Migration {
  Migration(
    version: v,
    name: n,
    up: "DROP INDEX IF EXISTS " <> index,
    down: None,
  )
}

pub fn add_constraint(
  version v: Int,
  name n: String,
  table table: String,
  constraint constraint: String,
  definition definition: String,
) -> Migration {
  Migration(
    version: v,
    name: n,
    up: "ALTER TABLE "
      <> table
      <> " ADD CONSTRAINT "
      <> constraint
      <> " "
      <> definition,
    down: Some(
      "ALTER TABLE " <> table <> " DROP CONSTRAINT " <> constraint,
    ),
  )
}

pub fn drop_constraint(
  version v: Int,
  name n: String,
  table table: String,
  constraint constraint: String,
) -> Migration {
  Migration(
    version: v,
    name: n,
    up: "ALTER TABLE " <> table <> " DROP CONSTRAINT " <> constraint,
    down: None,
  )
}

// ── helpers ────────────────────────────────────────────────────────────────

fn column_def(col: Column) -> String {
  let null_sql = case col.nullable {
    True -> ""
    False -> " NOT NULL"
  }
  let default_sql = case col.default {
    None -> ""
    Some(expr) -> " DEFAULT " <> expr
  }
  let pk_sql = case col.primary_key {
    True -> " PRIMARY KEY"
    False -> ""
  }
  let unique_sql = case col.unique {
    True -> " UNIQUE"
    False -> ""
  }
  col.name <> " " <> col.type_sql <> pk_sql <> unique_sql <> null_sql <> default_sql
}
