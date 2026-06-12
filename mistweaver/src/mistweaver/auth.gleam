import gleam/int
import gleam/option.{None, Some}
import mist.{type Connection}
import mistweaver/conn.{type Conn, AuthUser, Conn}
import mistweaver/response as mw_response
import mistweaver/router.{type Middleware}
import mistweaver/session

/// Read the session and populate `conn.auth` if valid credentials are present.
/// Never redirects — use as a global middleware so all handlers can read the
/// current user from `conn.auth` regardless of whether the route is protected.
pub fn load(secret: String) -> Middleware(Connection) {
  fn(c, next) { next(load_conn(c, secret)) }
}

/// Like `load/1` but redirects to `redirect` if the user is not authenticated.
/// Use in a `router.scope` to protect a group of routes.
pub fn require(secret: String, to redirect: String) -> Middleware(Connection) {
  fn(c, next) {
    let c2 = load_conn(c, secret)
    case c2.auth {
      Some(_) -> next(c2)
      None -> mw_response.redirect(302, to: redirect)
    }
  }
}

fn load_conn(c: Conn(Connection), secret: String) -> Conn(Connection) {
  let sess = session.get(c.request, secret)
  case session.fetch(sess, "user_id"), session.fetch(sess, "username") {
    Some(uid_str), Some(username) ->
      case int.parse(uid_str) {
        Ok(id) -> Conn(..c, auth: Some(AuthUser(id:, username:)))
        Error(_) -> c
      }
    _, _ -> c
  }
}
