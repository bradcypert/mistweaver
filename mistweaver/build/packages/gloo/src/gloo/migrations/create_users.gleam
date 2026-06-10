import gloo/migration.{type Migration}
import gloo/pg

pub fn migration() -> Migration {
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
