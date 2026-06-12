# changeset

Validates form parameters without reflection. Built on `Dict(String, String)`.

## Types

```gleam
pub type Changeset {
  Changeset(
    params: Dict(String, String),
    errors: Dict(String, List(String)),
    valid: Bool,
  )
}
```

## Functions

### `cast`
```gleam
pub fn cast(params: List(#(String, String)), required required_fields: List(String)) -> Changeset
```
Build a changeset from raw form params. Marks the changeset invalid if any required field is missing or blank after trimming.

---

### `get`
```gleam
pub fn get(cs: Changeset, field: String) -> Option(String)
```
Return the raw value for a field, or `None` if not present.

---

### `get_or`
```gleam
pub fn get_or(cs: Changeset, field: String, default: String) -> String
```
Return the value for a field, or `default` if absent.

---

### `validate_length`
```gleam
pub fn validate_length(cs: Changeset, field: String, min min_opt: Option(Int), max max_opt: Option(Int)) -> Changeset
```
Validate the trimmed length of a field. Pass `None` to skip either bound.

---

### `validate_format`
```gleam
pub fn validate_format(cs: Changeset, field: String, with validator: fn(String) -> Bool, message message: String) -> Changeset
```
Validate the field value with a predicate. Adds `message` as the error if the predicate returns `False`.

---

### `validate_inclusion`
```gleam
pub fn validate_inclusion(cs: Changeset, field: String, in values: List(String)) -> Changeset
```
Validate that the field value is one of the accepted values.

---

### `errors_for`
```gleam
pub fn errors_for(cs: Changeset, field: String) -> List(String)
```
Return all error messages for a field, or `[]` if none.

---

### `valid`
```gleam
pub fn valid(cs: Changeset) -> Bool
```
`True` if the changeset has no errors.
