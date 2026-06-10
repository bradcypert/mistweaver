////  Adapter-agnostic parameter value type.
////
////  Use these constructors in `sql` and `query` modules — they are encoded
////  to DB-specific wire types by the adapter at execution time.

import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}

pub type GlooValue {
  GString(String)
  GInt(Int)
  GFloat(Float)
  GBool(Bool)
  GBitArray(BitArray)
  GTimestamp(Timestamp)
  GNull
  /// Postgres-only: used for UNNEST / array parameters.
  /// SQLite adapter will return DbError if this is encountered.
  GArray(List(GlooValue))
  /// Postgres text[] — use with = ANY($N) or UNNEST.
  /// SQLite adapter will return DbError; use manual IN (?,?,?) instead.
  GStringArray(List(String))
  /// Postgres int8[] — use with = ANY($N) or UNNEST.
  /// SQLite adapter will return DbError; use manual IN (?,?,?) instead.
  GIntArray(List(Int))
}

pub fn nullable(encoder: fn(a) -> GlooValue, v: Option(a)) -> GlooValue {
  case v {
    option.None -> GNull
    option.Some(a) -> encoder(a)
  }
}
