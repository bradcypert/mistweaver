# Mailer

The `mailer` module provides a simple `Email` builder and a pluggable `Adapter` interface.

## Building an email

```gleam
import mistweaver/mailer

let email =
  mailer.new()
  |> mailer.to("user@example.com")
  |> mailer.from("no-reply@myapp.com")
  |> mailer.subject("Welcome to MyApp")
  |> mailer.text_body("Thanks for signing up!")
  |> mailer.html_body("<h1>Thanks for signing up!</h1>")
```

## Sending

```gleam
case mailer.send(email, via: adapter) {
  Ok(_)      -> // sent
  Error(msg) -> // handle failure
}
```

## Adapters

### Log adapter (development)

Prints email details to stdout. Good for development and CI:

```gleam
let adapter = mailer.log_adapter()
```

### Test adapter

Captures sent emails in memory for assertions in tests:

```gleam
let #(adapter, get_sent) = mailer.test_adapter()

mailer.send(welcome_email, via: adapter)

let sent = get_sent()
// [Email(to: ["user@example.com"], subject: "Welcome to MyApp", ...)]
```

### Custom adapter

Implement any adapter by wrapping your SMTP client or HTTP API:

```gleam
let smtp_adapter = mailer.Adapter(send_fn: fn(email) {
  smtp.deliver(email.to, email.from, email.subject, email.text_body)
})
```
