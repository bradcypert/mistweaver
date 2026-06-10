////  Input validation combinators.  `validate.struct` collects ALL field errors
////  before returning — it never short-circuits.
////
////  ```gleam
////  validate.struct([
////    validate.field("email", email, [validate.format("^[^@]+@[^@]+$")]),
////    validate.field("name",  name,  [validate.max_length(100)]),
////  ])
////  // -> Result(List(value), List(validate.Error))
////  ```

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/regexp
import gleam/string

pub type Error {
  FieldError(field: String, message: String)
}

// ── struct (V7: collect ALL errors, never short-circuit) ───────────────────

/// Returns Ok(values) when every field passes, Error(all_errors) otherwise.
/// Processes every field even after a failure — never short-circuits.
pub fn struct(fields: List(Result(a, List(Error)))) -> Result(List(a), List(Error)) {
  let errors =
    list.flat_map(fields, fn(r) {
      case r {
        Ok(_) -> []
        Error(errs) -> errs
      }
    })
  case errors {
    [] ->
      Ok(
        list.filter_map(fields, fn(r) {
          case r {
            Ok(v) -> Ok(v)
            Error(_) -> Error(Nil)
          }
        }),
      )
    _ -> Error(errors)
  }
}

// ── field validator ────────────────────────────────────────────────────────

/// Validate a single field against a list of rules.
/// Runs every rule regardless of prior failures.
pub fn field(
  name: String,
  value: a,
  rules: List(fn(a) -> Result(Nil, String)),
) -> Result(a, List(Error)) {
  let errs =
    list.filter_map(rules, fn(rule) {
      case rule(value) {
        Ok(_) -> Error(Nil)
        Error(msg) -> Ok(FieldError(field: name, message: msg))
      }
    })
  case errs {
    [] -> Ok(value)
    _ -> Error(errs)
  }
}

// ── required (Option unwrap) ───────────────────────────────────────────────

pub fn required(field_name: String, value: Option(a)) -> Result(a, List(Error)) {
  case value {
    Some(v) -> Ok(v)
    None ->
      Error([FieldError(field: field_name, message: "is required")])
  }
}

// ── string rules ───────────────────────────────────────────────────────────

pub fn max_length(n: Int) -> fn(String) -> Result(Nil, String) {
  fn(s) {
    case string.length(s) <= n {
      True -> Ok(Nil)
      False ->
        Error("must be at most " <> int.to_string(n) <> " characters long")
    }
  }
}

pub fn length(n: Int) -> fn(String) -> Result(Nil, String) {
  fn(s) {
    case string.length(s) == n {
      True -> Ok(Nil)
      False ->
        Error("must be exactly " <> int.to_string(n) <> " characters long")
    }
  }
}

pub fn format(pattern: String) -> fn(String) -> Result(Nil, String) {
  fn(s) {
    case regexp.from_string(pattern) {
      Error(_) -> Error("invalid format pattern")
      Ok(re) ->
        case regexp.check(with: re, content: s) {
          True -> Ok(Nil)
          False -> Error("has invalid format")
        }
    }
  }
}

// ── numeric rules (Int) ────────────────────────────────────────────────────

pub fn gte(minimum: Int) -> fn(Int) -> Result(Nil, String) {
  fn(v) {
    case v >= minimum {
      True -> Ok(Nil)
      False -> Error("must be >= " <> int.to_string(minimum))
    }
  }
}

pub fn lte(maximum: Int) -> fn(Int) -> Result(Nil, String) {
  fn(v) {
    case v <= maximum {
      True -> Ok(Nil)
      False -> Error("must be <= " <> int.to_string(maximum))
    }
  }
}
