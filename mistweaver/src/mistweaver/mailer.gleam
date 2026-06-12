import gleam/dict.{type Dict}
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/string

pub type Email {
  Email(
    to: List(String),
    from: String,
    subject: String,
    text_body: Option(String),
    html_body: Option(String),
    headers: Dict(String, String),
  )
}

pub opaque type Adapter {
  Adapter(send_fn: fn(Email) -> Result(Nil, String))
}

pub type SentEmail {
  SentEmail(email: Email)
}

/// Create a new blank email. Use the `with_*` helpers to populate fields.
pub fn new() -> Email {
  Email(
    to: [],
    from: "",
    subject: "",
    text_body: None,
    html_body: None,
    headers: dict.new(),
  )
}

pub fn to(email: Email, address: String) -> Email {
  Email(..email, to: [address, ..email.to])
}

pub fn from(email: Email, address: String) -> Email {
  Email(..email, from: address)
}

pub fn subject(email: Email, subject: String) -> Email {
  Email(..email, subject: subject)
}

pub fn text_body(email: Email, body: String) -> Email {
  Email(..email, text_body: Some(body))
}

pub fn html_body(email: Email, body: String) -> Email {
  Email(..email, html_body: Some(body))
}

pub fn header(email: Email, name: String, value: String) -> Email {
  Email(..email, headers: dict.insert(email.headers, name, value))
}

/// Send the email through the given adapter.
pub fn send(email: Email, via adapter: Adapter) -> Result(Nil, String) {
  adapter.send_fn(email)
}

/// An adapter that logs emails to stdout. Useful in development.
pub fn log_adapter() -> Adapter {
  Adapter(send_fn: fn(email) {
    let recipients = string.join(email.to, ", ")
    io.println("[Mailer] To: " <> recipients)
    io.println("[Mailer] From: " <> email.from)
    io.println("[Mailer] Subject: " <> email.subject)
    case email.text_body {
      Some(body) -> io.println("[Mailer] Body:\n" <> body)
      None -> Nil
    }
    Ok(Nil)
  })
}

/// An adapter that captures sent emails in a list for inspection in tests.
/// Call `sent/1` on the returned subject to retrieve what was sent.
pub fn test_adapter() -> #(Adapter, fn() -> List(Email)) {
  let sent_ref = list_ref_new()
  let adapter =
    Adapter(send_fn: fn(email) {
      list_ref_push(sent_ref, email)
      Ok(Nil)
    })
  let get_sent = fn() { list_ref_get(sent_ref) }
  #(adapter, get_sent)
}

@external(erlang, "mistweaver_mailer_ffi", "list_ref_new")
fn list_ref_new() -> a

@external(erlang, "mistweaver_mailer_ffi", "list_ref_push")
fn list_ref_push(ref: a, item: b) -> Nil

@external(erlang, "mistweaver_mailer_ffi", "list_ref_get")
fn list_ref_get(ref: a) -> List(b)
