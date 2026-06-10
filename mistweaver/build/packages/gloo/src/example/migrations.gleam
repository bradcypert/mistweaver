import gloo/migration.{type Migration}
import gloo/pg

pub fn all() -> List(Migration) {
  [create_users(), create_posts(), create_follows()]
}

fn create_users() -> Migration {
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
}

fn create_posts() -> Migration {
  migration.create_table(
    version: 20_260_430_000_002,
    name: "create_posts",
    table: "posts",
    columns: [
      pg.column("id", pg.BigSerial) |> pg.primary_key,
      pg.column("user_id", pg.BigInt) |> pg.not_null,
      pg.column("body", pg.Text) |> pg.not_null,
      pg.column("inserted_at", pg.TimestampTz)
        |> pg.not_null
        |> pg.default("NOW()"),
    ],
  )
  |> migration.with_down("DROP TABLE IF EXISTS posts")
}

fn create_follows() -> Migration {
  migration.create_table(
    version: 20_260_430_000_003,
    name: "create_follows",
    table: "follows",
    columns: [
      pg.column("follower_id", pg.BigInt) |> pg.not_null,
      pg.column("followee_id", pg.BigInt) |> pg.not_null,
      pg.column("inserted_at", pg.TimestampTz)
        |> pg.not_null
        |> pg.default("NOW()"),
    ],
  )
}
