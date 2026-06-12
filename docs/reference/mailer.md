# mailer

Email sending with a pluggable adapter interface.

## Types

```gleam
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

pub opaque type Adapter
```

## Builder functions

### `new`
```gleam
pub fn new() -> Email
```
Create a blank email. Use the `to`, `from`, `subject`, `text_body`, `html_body`, and `header` helpers to populate it.

---

### `to` / `from` / `subject` / `text_body` / `html_body` / `header`
```gleam
pub fn to(email: Email, address: String) -> Email
pub fn from(email: Email, address: String) -> Email
pub fn subject(email: Email, subject: String) -> Email
pub fn text_body(email: Email, body: String) -> Email
pub fn html_body(email: Email, body: String) -> Email
pub fn header(email: Email, name: String, value: String) -> Email
```
Builder helpers. `to` may be called multiple times to add multiple recipients.

## Sending

### `send`
```gleam
pub fn send(email: Email, via adapter: Adapter) -> Result(Nil, String)
```
Send through the given adapter.

## Adapters

### `log_adapter`
```gleam
pub fn log_adapter() -> Adapter
```
Prints email details to stdout. Use in development.

---

### `test_adapter`
```gleam
pub fn test_adapter() -> #(Adapter, fn() -> List(Email))
```
Captures sent emails in memory. The second return value is a getter for the captured list — use it in test assertions.

---

### `adapter`
```gleam
pub fn adapter(send_fn: fn(Email) -> Result(Nil, String)) -> Adapter
```
Build a custom adapter from any send function. Use this to integrate with an SMTP client, Postmark, Mailgun, etc.

See `mistweaver/mailer/postmark` for a ready-made Postmark adapter.
