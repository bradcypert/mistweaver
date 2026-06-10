import gleam/bit_array
import gleam/crypto
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/option.{type Option, None, Some}
import gleam/string
import mist.{type ResponseData}
import mistweaver/request as mw_request

/// A one-request flash notification stored in a separate signed cookie.
pub type Flash {
  Flash(kind: String, message: String)
}

const cookie_name = "_mw_flash"

/// Store a flash message on the response. Stacks correctly alongside a session
/// cookie because it prepends the Set-Cookie header rather than replacing it.
pub fn put(
  resp: Response(ResponseData),
  secret: String,
  kind: String,
  message: String,
) -> Response(ResponseData) {
  let payload = kind <> "|" <> message
  let signed =
    crypto.sign_message(<<payload:utf8>>, <<secret:utf8>>, crypto.Sha256)
  let cookie =
    cookie_name <> "=" <> signed <> "; Path=/; HttpOnly; SameSite=Lax"
  response.Response(..resp, headers: [#("set-cookie", cookie), ..resp.headers])
}

/// Read the flash from the request and return a function that clears it.
/// Pattern:
///   let #(flash_opt, clear) = flash.consume(req, secret)
///   mw_response.html(200, render(flash_opt)) |> clear
pub fn consume(
  req: Request(body),
  secret: String,
) -> #(Option(Flash), fn(Response(ResponseData)) -> Response(ResponseData)) {
  let flash_opt = case mw_request.get_cookie(req, cookie_name) {
    None -> None
    Some(signed) ->
      case crypto.verify_signed_message(signed, <<secret:utf8>>) {
        Error(_) -> None
        Ok(payload) ->
          case bit_array.to_string(payload) {
            Error(_) -> None
            Ok(s) ->
              case string.split_once(s, "|") {
                Ok(#(kind, message)) -> Some(Flash(kind:, message:))
                Error(_) -> None
              }
          }
      }
  }
  let clear = fn(resp: Response(ResponseData)) {
    let cookie =
      cookie_name <> "=; Path=/; HttpOnly; Max-Age=0; SameSite=Lax"
    response.Response(..resp, headers: [
      #("set-cookie", cookie),
      ..resp.headers
    ])
  }
  #(flash_opt, clear)
}
