import gleam/json
import gleam/list
import gleam/option.{Some}
import gleam/string
import mistweaver/mailer.{type Adapter, type Email}

/// Return a mailer adapter that sends via the Postmark API.
///
///   let adapter = postmark.adapter(api_key: "your-server-token")
///   mailer.send(email, via: adapter)
///
/// Set the `POSTMARK_API_KEY` environment variable and pass it in via
/// `config.require("POSTMARK_API_KEY")`.
pub fn adapter(api_key api_key: String) -> Adapter {
  mailer.adapter(fn(email) { send(email, api_key) })
}

fn send(email: Email, api_key: String) -> Result(Nil, String) {
  let body = build_body(email)
  let headers = [
    #("X-Postmark-Server-Token", api_key),
    #("Accept", "application/json"),
  ]
  case
    http_post(
      "https://api.postmarkapp.com/email",
      headers,
      "application/json",
      body,
    )
  {
    Ok(#(status, _)) if status >= 200 && status < 300 -> Ok(Nil)
    Ok(#(status, resp)) ->
      Error(
        "Postmark returned status "
        <> string.inspect(status)
        <> ": "
        <> resp,
      )
    Error(reason) -> Error("HTTP error: " <> reason)
  }
}

fn build_body(email: Email) -> String {
  let to_str = string.join(email.to, ",")
  let fields =
    [
      Some(#("From", json.string(email.from))),
      Some(#("To", json.string(to_str))),
      Some(#("Subject", json.string(email.subject))),
      option.map(email.text_body, fn(b) { #("TextBody", json.string(b)) }),
      option.map(email.html_body, fn(b) { #("HtmlBody", json.string(b)) }),
    ]
    |> list.filter_map(fn(x) { option.to_result(x, Nil) })

  json.object(fields) |> json.to_string
}

@external(erlang, "mistweaver_http_ffi", "post")
fn http_post(
  url: String,
  headers: List(#(String, String)),
  content_type: String,
  body: String,
) -> Result(#(Int, String), String)
