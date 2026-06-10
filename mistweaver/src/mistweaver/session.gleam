import gleam/bit_array
import gleam/crypto
import gleam/dict.{type Dict}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import mist.{type ResponseData}
import mistweaver/request as mw_request

/// A session is a key-value map stored in a signed cookie.
/// Values must not contain `=` or `&` characters.
pub type Session =
  Dict(String, String)

const cookie_name = "_mw_session"

/// Read and verify the session from the incoming request cookie.
/// Returns an empty session if the cookie is absent or tampered with.
pub fn get(req: Request(body), secret: String) -> Session {
  case mw_request.get_cookie(req, cookie_name) {
    None -> dict.new()
    Some(value) ->
      case crypto.verify_signed_message(value, <<secret:utf8>>) {
        Ok(payload) ->
          case bit_array.to_string(payload) {
            Ok(s) -> decode_session(s)
            Error(_) -> dict.new()
          }
        Error(_) -> dict.new()
      }
  }
}

/// Sign the session and attach it as an HttpOnly cookie on the response.
/// Uses header prepending so multiple Set-Cookie headers stack correctly.
pub fn put(
  resp: Response(ResponseData),
  session: Session,
  secret: String,
) -> Response(ResponseData) {
  let payload = encode_session(session)
  let signed =
    crypto.sign_message(<<payload:utf8>>, <<secret:utf8>>, crypto.Sha256)
  let cookie =
    cookie_name <> "=" <> signed <> "; Path=/; HttpOnly; SameSite=Lax"
  response.Response(..resp, headers: [#("set-cookie", cookie), ..resp.headers])
}

/// Clear the session cookie.
pub fn delete(resp: Response(ResponseData)) -> Response(ResponseData) {
  let cookie = cookie_name <> "=; Path=/; HttpOnly; Max-Age=0; SameSite=Lax"
  response.Response(..resp, headers: [#("set-cookie", cookie), ..resp.headers])
}

pub fn empty() -> Session {
  dict.new()
}

pub fn set(session: Session, key: String, value: String) -> Session {
  dict.insert(session, key, value)
}

pub fn fetch(session: Session, key: String) -> Option(String) {
  dict.get(session, key) |> option.from_result
}

pub fn delete_key(session: Session, key: String) -> Session {
  dict.delete(session, key)
}

fn encode_session(session: Session) -> String {
  session
  |> dict.to_list
  |> list.map(fn(pair) { pair.0 <> "=" <> pair.1 })
  |> string.join("&")
}

fn decode_session(encoded: String) -> Session {
  case encoded {
    "" -> dict.new()
    _ ->
      encoded
      |> string.split("&")
      |> list.filter_map(fn(pair) {
        case string.split_once(pair, "=") {
          Ok(kv) -> Ok(kv)
          Error(_) -> Error(Nil)
        }
      })
      |> dict.from_list
  }
}
