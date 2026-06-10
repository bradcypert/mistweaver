# gloo

[![Package Version](https://img.shields.io/hexpm/v/gloo)](https://hex.pm/packages/gloo)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gloo/)

A small, practical database library for Gleam. Supports **Postgres** and
**SQLite** with the same API. The query builder handles 80% of CRUD work; the
`sql` module covers the rest with typed raw SQL. No magic, no macros — just
composable values and the Gleam standard library.

```sh
gleam add gloo
```

---

## Getting started

### 1. Connect

**Postgres**

```gleam
import gloo/adapter/postgres

pub fn start_repo() {
  postgres.default_config()
  |> postgres.database("myapp_dev")
  |> postgres.user("postgres")
  |> postgres.start()
  // -> Result(Repo, actor.StartError)
}
```

**SQLite**

```gleam
import gloo/adapter/sqlite

pub fn start_repo() {
  sqlite.start(sqlite.file("myapp.sqlite3"))
  // sqlite.start(sqlite.memory())  -- for tests or ephemeral data
  // -> Result(Repo, String)
}
```

Both return a `Repo` value. Every query function in gloo takes a `Repo` — the
adapter is the only thing that differs between the two backends.

> **Tip:** SQLite's `:memory:` adapter is great for tests — no setup, no
> teardown, and migrations run in milliseconds.

### 2. Define a schema

A `Table(t)` pairs a table name with a row decoder. Decoders read positional
columns using `gleam/dynamic/decode`.

```gleam
import gleam/dynamic/decode
import gloo/schema.{type Table, Table}

pub type User {
  User(id: Int, email: String, name: String)
}

pub fn users() -> Table(User) {
  let decoder = {
    use id    <- decode.field(0, decode.int)
    use email <- decode.field(1, decode.string)
    use name  <- decode.field(2, decode.string)
    decode.success(User(id:, email:, name:))
  }
  Table(name: "users", primary_key: "id", decoder:)
}
```

The schema definition is identical for Postgres and SQLite — only the migration
column types differ (see step 3).

### 3. Write migrations

Column types live in the DB-specific modules. Using the wrong module's types
with a given adapter is a compile error.

**Postgres** — `gloo/pg`

```gleam
import gloo/migration.{type Migration}
import gloo/pg

pub fn create_users() -> Migration {
  migration.create_table(
    version: 20_260_430_000_001,
    name: "create_users",
    table: "users",
    columns: [
      pg.column("id", pg.BigSerial) |> pg.primary_key,
      pg.column("email", pg.Text) |> pg.not_null |> pg.unique,
      pg.column("name", pg.Text) |> pg.not_null,
      pg.column("inserted_at", pg.TimestampTz)
        |> pg.not_null
        |> pg.default("NOW()"),
    ],
  )
  |> migration.with_down("DROP TABLE IF EXISTS users")
}
```

Postgres column types: `BigSerial`, `BigInt`, `Boolean`, `Integer`,
`Numeric(p, s)`, `Text`, `Varchar(n)`, `TimestampTz`, `Uuid`, `Jsonb`, `ByteA`.

**SQLite** — `gloo/sqlite`

```gleam
import gloo/migration.{type Migration}
import gloo/sqlite

pub fn create_notes() -> Migration {
  migration.create_table(
    version: 1,
    name: "create_notes",
    table: "notes",
    columns: [
      sqlite.column("id", sqlite.Integer) |> sqlite.primary_key,
      sqlite.column("body", sqlite.Text) |> sqlite.not_null,
    ],
  )
  |> migration.with_down("DROP TABLE IF EXISTS notes")
}
```

SQLite column types: `Integer`, `Text`, `Real`, `Blob`. Autoincrement is
implicit on an `Integer` `primary_key` column via SQLite's rowid mechanism.

Other DDL helpers (both backends): `drop_table`, `rename_table`, `add_column`,
`drop_column`, `rename_column`, `change_column`, `create_index`, `drop_index`,
`add_constraint`, `drop_constraint`, `execute_sql`.

### 4. Run migrations

Create a module in your app that serves as the migration entry point — for
example `src/myapp/db.gleam`:

```gleam
import gleam/result
import gloo/adapter/postgres
import gloo/migrate

pub fn main() {
  use repo <- result.try(postgres.start(postgres.default_config()))
  migrate.main_with_migrations(repo, [
    create_users(),
    // add more migrations here
  ])
}
```

Then run it with `-m <module>`:

```sh
gleam run -m myapp/db -- migrate up          # apply all pending
gleam run -m myapp/db -- migrate up --step 1 # apply one
gleam run -m myapp/db -- migrate down        # roll back one
gleam run -m myapp/db -- migrate status      # show applied/pending
gleam run -m myapp/db -- migrate gen name    # print a migration template
```

Migrations track applied versions in a `schema_migrations` table that is
created automatically. Each migration runs in its own transaction. Running
`up` twice is safe — already-applied versions are skipped.

### 5. Query with the query builder

```gleam
import gloo/query
import gloo/repo
import gloo/sql

// SELECT * FROM users WHERE email = $1
pub fn find_user(r, email) {
  query.from(users())
  |> query.where(query.Eq("email", sql.string(email)))
  |> repo.query_one(r, _)
}

// INSERT INTO users (email, name) VALUES ($1, $2) RETURNING id, email, name
pub fn create_user(r, email, name) {
  query.insert(query.from(users()), users(), [
    #("email", sql.string(email)),
    #("name", sql.string(name)),
  ])
  |> query.returning_columns(["id", "email", "name"])
  |> query.returning(users().decoder)
  |> repo.query_one(r, _)
}

// UPDATE users SET name = $1 WHERE id = $2
pub fn rename_user(r, id, name) {
  query.from(users())
  |> query.update([#("name", sql.string(name))])
  |> query.where(query.Eq("id", sql.int(id)))
  |> repo.query_execute(r, _)
}

// DELETE FROM users WHERE id = $1
pub fn delete_user(r, id) {
  query.from(users())
  |> query.delete
  |> query.where(query.Eq("id", sql.int(id)))
  |> repo.query_execute(r, _)
}
```

Available predicates: `Eq`, `Neq`, `Gt`, `Gte`, `Lt`, `Lte`, `In`, `Like`,
`IsNull`, `IsNotNull`, `And([…])`, `Or([…])`, `Not(cond)`.

### 6. Raw SQL with the `sql` module

Use the `sql` module when a query spans multiple tables or needs features the
builder does not cover.

```gleam
import gleam/dynamic/decode
import gloo/sql
import gloo/repo

pub type FeedPost {
  FeedPost(post_id: Int, author: String, body: String)
}

pub fn feed(r, user_id, limit) {
  let decoder = {
    use post_id <- decode.field(0, decode.int)
    use author  <- decode.field(1, decode.string)
    use body    <- decode.field(2, decode.string)
    decode.success(FeedPost(post_id:, author:, body:))
  }
  sql.query(
    "SELECT p.id, u.name, p.body
     FROM posts p
     JOIN users u ON u.id = p.user_id
     WHERE p.user_id IN (
       SELECT followee_id FROM follows WHERE follower_id = $1
     )
     ORDER BY p.inserted_at DESC
     LIMIT $2",
  )
  |> sql.param(sql.int(user_id))
  |> sql.param(sql.int(limit))
  |> sql.returns(decoder)
  |> repo.sql_all(r, _)
}
```

Value constructors: `sql.string`, `sql.int`, `sql.bool`, `sql.time`
(`birl.Time`), `sql.uuid`, `sql.nullable`. Helper: `sql.in_clause` produces
offset-aware `($n, $n+1, …)` placeholders.

### 7. Validate input

`validate.struct` runs every rule and collects all failures — it never
short-circuits.

```gleam
import gloo/validate

pub fn validate_user(email: String, name: String) {
  validate.struct([
    validate.field("email", email, [
      validate.format("^[^@]+@[^@]+$"),
      validate.max_length(255),
    ]),
    validate.field("name", name, [
      validate.max_length(100),
    ]),
  ])
}
```

Returns `Result(List(value), List(validate.Error))`. Each `validate.Error` is a
`FieldError(field: String, message: String)`.

### 8. Transactions

```gleam
import gloo/repo
import gleam/result

pub fn transfer(r, from_id, to_id, amount) {
  repo.transaction(r, fn(tx) {
    use _ <- result.try(debit(tx, from_id, amount))
    use _ <- result.try(credit(tx, to_id, amount))
    Ok(Nil)
  })
}
```

`Ok` commits, `Error` rolls back. Nested `repo.transaction` calls automatically
become savepoints — no extra API surface.

### 9. Telemetry

```gleam
import gloo/telemetry

let t = telemetry.with_handler(fn(event) {
  case event {
    telemetry.QueryStart(sql:, params_count:) -> log_start(sql, params_count)
    telemetry.QueryEnd(sql:, duration_ms:, rows:) -> log_end(sql, duration_ms, rows)
    telemetry.QueryError(sql:, reason:) -> log_error(sql, reason)
    telemetry.TransactionStart -> log("tx_start")
    telemetry.TransactionCommit -> log("tx_commit")
    telemetry.TransactionRollback -> log("tx_rollback")
  }
})

let repo = postgres.start(config) |> result.map(repo.with_telemetry(_, t))
```

### 10. Error handling

```gleam
import gloo/error.{type GlooError}

case repo.query_one(r, q) {
  Ok(user) -> Ok(user)
  Error(error.NoResultError) -> Error("not found")
  Error(error.TooManyResultsError(_)) -> Error("ambiguous")
  Error(error.ConstraintError(name)) -> Error("conflict: " <> name)
  Error(error.DbError(msg)) -> Error("db: " <> msg)
  Error(error.RollbackError) -> Error("rolled back")
}
```

Map constraint names to typed application errors with `error.map_constraints`:

```gleam
error.map_constraints(result, [
  #("users_email_key", MyError.EmailTaken),
])
```

---

## Module overview

| module | purpose |
|---|---|
| `gloo/adapter/postgres` | start a Postgres connection pool |
| `gloo/adapter/sqlite` | open a SQLite connection |
| `gloo/repo` | execute queries and manage transactions |
| `gloo/query` | single-table query builder |
| `gloo/sql` | typed raw SQL builder |
| `gloo/schema` | `Table(t)` value with decoder |
| `gloo/pg` | Postgres column types for migrations |
| `gloo/sqlite` | SQLite column types for migrations |
| `gloo/migration` | DDL migration DSL |
| `gloo/migrate` | migration CLI runner |
| `gloo/validate` | input validation combinators |
| `gloo/error` | `GlooError` type and helpers |
| `gloo/telemetry` | event hooks |

---

## Development

```sh
gleam test   # run the test suite (126 tests, no DB required)
gleam build  # type-check all modules
```

Further documentation: <https://hexdocs.pm/gloo>
