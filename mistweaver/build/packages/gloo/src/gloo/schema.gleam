////  A `Table(t)` value pairs a Postgres table name with a row decoder.
////  Pass it to `query.from` to start a query, or to `migration.create_table`
////  to define the schema.

import gleam/dynamic/decode.{type Decoder}

pub type Table(t) {
  Table(name: String, primary_key: String, decoder: Decoder(t))
}
