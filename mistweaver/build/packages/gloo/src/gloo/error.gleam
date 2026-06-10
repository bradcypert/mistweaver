////  All errors returned by gloom repo functions are wrapped in `GlooError`.
////
////  Use `map_constraint` or `map_constraints` to convert `ConstraintError`
////  into application-specific error types without losing the constraint name.

import gleam/dynamic/decode.{type DecodeError}
import gleam/result
import pog
import sqlight

pub type GlooError {
  NoResultError
  TooManyResultsError(count: Int)
  ConstraintError(name: String)
  DbError(message: String)
  RollbackError
}

pub fn from_pog(e: pog.QueryError) -> GlooError {
  case e {
    pog.ConstraintViolated(constraint: name, ..) -> ConstraintError(name)
    pog.PostgresqlError(message: msg, ..) -> DbError(msg)
    pog.UnexpectedResultType(errors) ->
      DbError("decode error: " <> decode_errors_to_string(errors))
    pog.UnexpectedArgumentCount(expected: e, got: g) ->
      DbError(
        "wrong argument count: expected "
        <> int_to_string(e)
        <> " got "
        <> int_to_string(g),
      )
    pog.UnexpectedArgumentType(expected: e, got: g) ->
      DbError("wrong argument type: expected " <> e <> " got " <> g)
    pog.QueryTimeout -> DbError("query timeout")
    pog.ConnectionUnavailable -> DbError("connection unavailable")
  }
}

pub fn from_sqlight(e: sqlight.Error) -> GlooError {
  case e {
    sqlight.SqlightError(code: sqlight.ConstraintUnique, message: msg, ..) ->
      ConstraintError(msg)
    sqlight.SqlightError(code: sqlight.ConstraintPrimarykey, message: msg, ..) ->
      ConstraintError(msg)
    sqlight.SqlightError(code: sqlight.ConstraintCheck, message: msg, ..) ->
      ConstraintError(msg)
    sqlight.SqlightError(code: sqlight.ConstraintForeignkey, message: msg, ..) ->
      ConstraintError(msg)
    sqlight.SqlightError(message: msg, ..) -> DbError(msg)
  }
}

pub fn to_string(e: GlooError) -> String {
  case e {
    NoResultError -> "no result"
    TooManyResultsError(n) -> "too many results: " <> int_to_string(n)
    ConstraintError(name) -> "constraint error: " <> name
    DbError(msg) -> "db error: " <> msg
    RollbackError -> "transaction rolled back"
  }
}

/// Map a specific constraint violation to a typed error.
/// All other errors are re-wrapped via `fallback`.
///
/// Example:
///   repo.query_one(repo, q)
///   |> error.map_constraint("users_email_idx", EmailAlreadyTaken, DbFailed)
pub fn map_constraint(
  result: Result(t, GlooError),
  constraint_name: String,
  on_match: mapped_error,
  fallback: fn(GlooError) -> mapped_error,
) -> Result(t, mapped_error) {
  result.map_error(result, fn(e) {
    case e {
      ConstraintError(name) if name == constraint_name -> on_match
      _ -> fallback(e)
    }
  })
}

/// Match multiple constraint names to typed errors.
/// Falls back for any unrecognised constraint or non-constraint error.
pub fn map_constraints(
  result: Result(t, GlooError),
  mappings: List(#(String, mapped_error)),
  fallback: fn(GlooError) -> mapped_error,
) -> Result(t, mapped_error) {
  result.map_error(result, fn(e) {
    case e {
      ConstraintError(name) ->
        case find_mapping(mappings, name) {
          Ok(mapped) -> mapped
          Error(Nil) -> fallback(e)
        }
      _ -> fallback(e)
    }
  })
}

fn find_mapping(
  mappings: List(#(String, a)),
  name: String,
) -> Result(a, Nil) {
  case mappings {
    [] -> Error(Nil)
    [#(k, v), ..rest] ->
      case k == name {
        True -> Ok(v)
        False -> find_mapping(rest, name)
      }
  }
}

fn decode_errors_to_string(errors: List(DecodeError)) -> String {
  case errors {
    [] -> "unknown"
    [e, ..] -> e.expected <> " expected, got " <> e.found
  }
}

@external(erlang, "erlang", "integer_to_binary")
fn int_to_string(n: Int) -> String
