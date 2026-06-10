import gleam/http.{Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/option.{None, Some}
import gleam/string
import gloo/repo.{type Repo}
import mist.{type Connection, type ResponseData}
import mistweaver/csrf
import mistweaver/flash
import mistweaver/middleware
import mistweaver/request as mw_request
import mistweaver/response as mw_response
import mistweaver/session
import chirp/queries

pub fn create(
  repo: Repo,
  secret: String,
) -> fn(Request(Connection), List(#(String, String))) -> Response(ResponseData) {
  fn(req: Request(Connection), _params) {
    case req.method {
      Post ->
        middleware.body_limit(4096, fn(req2) {
          handle_create(repo, req2, secret)
        })(req, fn(_) { mw_response.not_found() })
      _ -> mw_response.not_found()
    }
  }
}

fn handle_create(
  repo: Repo,
  req: Request(BitArray),
  secret: String,
) -> Response(ResponseData) {
  let sess = session.get(req, secret)

  case session.fetch(sess, "user_id") {
    None ->
      mw_response.redirect(302, to: "/login")
      |> flash.put(secret, "error", "Please sign in to post a chirp.")
    Some(uid_str) ->
      case int.parse(uid_str) {
        Error(_) -> mw_response.redirect(302, to: "/login")
        Ok(user_id) -> {
          let params = mw_request.form_params(req)
          case csrf.validate(params, sess) {
            False ->
              mw_response.redirect(302, to: "/timeline")
              |> flash.put(
                secret,
                "error",
                "Invalid form submission. Please try again.",
              )
            True -> {
              let body =
                mw_request.form_param(params, "body") |> option.unwrap("")
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
                  case queries.create_chirp(repo, user_id, trimmed) {
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
      }
  }
}
