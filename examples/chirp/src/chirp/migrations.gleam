import gloo/migration.{type Migration}
import gloo/sqlite

pub fn all() -> List(Migration) {
  [create_users(), create_chirps()]
}

fn create_users() -> Migration {
  migration.create_table(
    20_260_524_000_001,
    "create_users",
    "users",
    [
      sqlite.column("id", sqlite.Integer) |> sqlite.primary_key,
      sqlite.column("username", sqlite.Text)
        |> sqlite.not_null
        |> sqlite.unique,
      sqlite.column("email", sqlite.Text) |> sqlite.not_null |> sqlite.unique,
      sqlite.column("password_hash", sqlite.Text) |> sqlite.not_null,
      sqlite.column("inserted_at", sqlite.Text)
        |> sqlite.not_null
        |> sqlite.default("(datetime('now'))"),
    ],
  )
}

fn create_chirps() -> Migration {
  migration.create_table(
    20_260_524_000_002,
    "create_chirps",
    "chirps",
    [
      sqlite.column("id", sqlite.Integer) |> sqlite.primary_key,
      sqlite.column("user_id", sqlite.Integer) |> sqlite.not_null,
      sqlite.column("body", sqlite.Text) |> sqlite.not_null,
      sqlite.column("inserted_at", sqlite.Text)
        |> sqlite.not_null
        |> sqlite.default("(datetime('now'))"),
    ],
  )
}
