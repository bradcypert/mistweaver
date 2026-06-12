import gleam/http.{Post}
import gleam/http/response.{type Response}
import gleam/option.{Some}
import gleam/string
import gloo/repo.{type Repo}
import mist.{type Connection, type ResponseData}
import mistweaver/conn.{type Conn}
import mistweaver/csrf
import mistweaver/flash
import mistweaver/middleware
import mistweaver/request as mw_request
import mistweaver/response as mw_response
import mistweaver/router.{type Params}
import mistweaver/session
import chirp/queries

pub fn create(
  repo: Repo,
  secret: String,
) -> fn(Conn(Connection), Params) -> Response(ResponseData) {
  fn(c: Conn(Connection), _params) {
    case c.request.method {
      Post ->
        middleware.body_limit(4096, fn(c2) {
          handle_create(repo, c2, secret)
        })(c, fn(_) { mw_response.not_found() })
      _ -> mw_response.not_found()
    }
  }
}

fn handle_create(
  repo: Repo,
  c: Conn(BitArray),
  secret: String,
) -> Response(ResponseData) {
  // auth is guaranteed by auth.require scope in router
  let assert Some(user) = c.auth
  let params = mw_request.form_params(c.request)
  let sess = session.get(c.request, secret)

  case csrf.validate(params, sess) {
    False ->
      mw_response.redirect(302, to: "/timeline")
      |> flash.put(secret, "error", "Invalid form submission. Please try again.")
    True -> {
      let body = mw_request.form_param(params, "body") |> option.unwrap("")
      let trimmed = string.trim(body)
      case string.is_empty(trimmed) || string.length(trimmed) > 280 {
        True ->
          mw_response.redirect(302, to: "/timeline")
          |> flash.put(
            secret,
            "error",
            "Chirps must be between 1 and 280 characters.",
          )
        False ->
          case queries.create_chirp(repo, user.id, trimmed) {
            Ok(_) -> mw_response.redirect(302, to: "/timeline")
            Error(_) ->
              mw_response.redirect(302, to: "/timeline")
              |> flash.put(
                secret,
                "error",
                "Something went wrong. Please try again.",
              )
          }
      }
    }
  }
}
