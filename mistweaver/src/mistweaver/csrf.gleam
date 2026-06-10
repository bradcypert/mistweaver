import gleam/bit_array
import gleam/crypto
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import mistweaver/session.{type Session}

const session_key = "_csrf"

/// Return the current CSRF token for this session, generating one if absent.
/// Returns the token and the (possibly updated) session — call `session.put`
/// on your response if the session changed.
pub fn token_for(sess: Session) -> #(String, Session) {
  case session.fetch(sess, session_key) {
    Some(t) -> #(t, sess)
    None -> {
      let t =
        crypto.strong_random_bytes(16)
        |> bit_array.base16_encode
        |> string.lowercase
      #(t, session.set(sess, session_key, t))
    }
  }
}

/// A `<input type="hidden" name="_csrf_token" value="...">` element for use
/// inside HTML forms.
pub fn hidden_input(token: String) -> Element(a) {
  html.input([
    attribute.type_("hidden"),
    attribute.name("_csrf_token"),
    attribute.value(token),
  ])
}

/// Validate the CSRF token submitted in a form against the session.
pub fn validate(
  form_params: List(#(String, String)),
  sess: Session,
) -> Bool {
  let submitted = find_param(form_params, "_csrf_token")
  let expected = session.fetch(sess, session_key)
  case submitted, expected {
    Some(t1), Some(t2) ->
      crypto.secure_compare(<<t1:utf8>>, <<t2:utf8>>)
    _, _ -> False
  }
}

fn find_param(params: List(#(String, String)), key: String) -> Option(String) {
  params
  |> list.find(fn(p) { p.0 == key })
  |> option_from_result
  |> option.map(fn(p) { p.1 })
}

fn option_from_result(r: Result(a, e)) -> Option(a) {
  case r {
    Ok(v) -> Some(v)
    Error(_) -> None
  }
}
