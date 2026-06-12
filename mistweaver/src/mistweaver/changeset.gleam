import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

pub type Changeset {
  Changeset(
    params: Dict(String, String),
    errors: Dict(String, List(String)),
    valid: Bool,
  )
}

/// Build a Changeset from raw form params, enforcing that all `required`
/// fields are present and non-empty. Other fields are available via `get/2`
/// but not checked until you add explicit validations.
pub fn cast(
  params: List(#(String, String)),
  required required_fields: List(String),
) -> Changeset {
  let params_dict = dict.from_list(params)
  let errors =
    required_fields
    |> list.filter_map(fn(field) {
      case dict.get(params_dict, field) {
        Error(_) -> Ok(#(field, ["is required"]))
        Ok(v) ->
          case string.is_empty(string.trim(v)) {
            True -> Ok(#(field, ["is required"]))
            False -> Error(Nil)
          }
      }
    })
    |> dict.from_list
  Changeset(params: params_dict, errors: errors, valid: dict.is_empty(errors))
}

/// Return the value for a field, or None if it wasn't submitted.
pub fn get(cs: Changeset, field: String) -> Option(String) {
  dict.get(cs.params, field) |> option.from_result
}

/// Return the value for a field, falling back to `default`.
pub fn get_or(cs: Changeset, field: String, default: String) -> String {
  get(cs, field) |> option.unwrap(default)
}

/// Validate that the field value's length falls within [min, max].
/// Pass `None` to skip either bound.
pub fn validate_length(
  cs: Changeset,
  field: String,
  min min_opt: Option(Int),
  max max_opt: Option(Int),
) -> Changeset {
  case dict.get(cs.params, field) {
    Error(_) -> cs
    Ok(value) -> {
      let len = string.length(string.trim(value))
      let errs =
        [
          case min_opt {
            Some(min) if len < min ->
              Some(
                "must be at least " <> int.to_string(min) <> " characters",
              )
            _ -> None
          },
          case max_opt {
            Some(max) if len > max ->
              Some("must be at most " <> int.to_string(max) <> " characters")
            _ -> None
          },
        ]
        |> list.filter_map(fn(x) { option.to_result(x, Nil) })
      add_errors(cs, field, errs)
    }
  }
}

/// Validate that the field value satisfies a predicate. Adds `message` as
/// the error if the predicate returns False.
pub fn validate_format(
  cs: Changeset,
  field: String,
  with validator: fn(String) -> Bool,
  message message: String,
) -> Changeset {
  case dict.get(cs.params, field) {
    Error(_) -> cs
    Ok(value) ->
      case validator(value) {
        True -> cs
        False -> add_errors(cs, field, [message])
      }
  }
}

/// Validate that the field value is one of the accepted values.
pub fn validate_inclusion(
  cs: Changeset,
  field: String,
  in values: List(String),
) -> Changeset {
  case dict.get(cs.params, field) {
    Error(_) -> cs
    Ok(value) ->
      case list.contains(values, value) {
        True -> cs
        False -> add_errors(cs, field, ["is not a valid value"])
      }
  }
}

/// Return all errors for a field, or an empty list if none.
pub fn errors_for(cs: Changeset, field: String) -> List(String) {
  dict.get(cs.errors, field) |> result.unwrap([])
}

/// True if there are no errors.
pub fn valid(cs: Changeset) -> Bool {
  cs.valid
}

fn add_errors(
  cs: Changeset,
  field: String,
  new_errors: List(String),
) -> Changeset {
  case new_errors {
    [] -> cs
    _ -> {
      let existing = dict.get(cs.errors, field) |> result.unwrap([])
      let updated =
        dict.insert(cs.errors, field, list.append(existing, new_errors))
      Changeset(..cs, errors: updated, valid: False)
    }
  }
}
