# Forms & Changesets

The `changeset` module validates form submissions without reflection or macros — just functions over `Dict(String, String)`.

## Casting params

```gleam
import mistweaver/changeset

let cs =
  form_params           // List(#(String, String)) from the request body
  |> changeset.cast(required: ["email", "password"])
```

`cast` marks the changeset invalid if any required field is missing or blank.

## Validations

Chain validations on a changeset:

```gleam
let cs =
  params
  |> changeset.cast(required: ["username", "email", "password"])
  |> changeset.validate_length("username", min: Some(3), max: Some(20))
  |> changeset.validate_length("password", min: Some(8), max: None)
  |> changeset.validate_format("email", with: fn(v) {
    string.contains(v, "@")
  }, message: "must be a valid email address")
```

## Checking validity

```gleam
case changeset.valid(cs) {
  False -> render_form_with_errors(cs)
  True  -> {
    let username = changeset.get_or(cs, "username", "")
    let email    = changeset.get_or(cs, "email", "")
    create_user(username, email)
  }
}
```

## Rendering errors

```gleam
let username_errors = changeset.errors_for(cs, "username")
// ["must be at least 3 characters"]
```

In a Lustre template:

```gleam
case changeset.errors_for(cs, "email") {
  [] -> html.text("")
  [first, ..] -> html.span([class("error")], [html.text(first)])
}
```

## Available validations

| Function | Description |
|---|---|
| `validate_length(field, min:, max:)` | String length bounds |
| `validate_format(field, with:, message:)` | Predicate on the value |
| `validate_inclusion(field, in:)` | Value must be in a list |
