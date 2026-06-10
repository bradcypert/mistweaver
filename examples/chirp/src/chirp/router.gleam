import gleam/http/request
import gleam/http/response
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gloo/error.{type GlooError}
import gloo/repo.{type Repo}
import lustre/attribute.{class}
import lustre/element
import lustre/element/html
import mist.{type Connection, type ResponseData}
import mistweaver/flash
import mistweaver/live
import mistweaver/middleware
import mistweaver/request as mw_request
import mistweaver/response as mw_response
import mistweaver/router
import mistweaver/session
import chirp/controllers/auth as auth_ctrl
import chirp/controllers/chirps as chirps_ctrl
import chirp/layout
import chirp/live/timeline
import chirp/queries

pub fn build(repo: Repo, secret: String) -> router.Router(Connection) {
  router.new()
  |> router.get("/", fn(req, _params) {
    let sess = session.get(req, secret)
    case session.fetch(sess, "user_id") {
      Some(_) -> mw_response.redirect(302, to: "/timeline")
      None -> mw_response.redirect(302, to: "/login")
    }
  })
  // Timeline: LiveView created per-request so it can close over the real session.
  |> router.get(
    "/timeline",
    live.dynamic_handler_with_shell(
      fn(req, _params) {
        let sess = session.get(req, secret)
        let user_id =
          session.fetch(sess, "user_id")
          |> option.then(fn(s) { int.parse(s) |> option.from_result })
        let username = session.fetch(sess, "username")
        timeline.make(repo, user_id, username)
      },
      fn(req, component) {
        let #(flash_opt, _clear) = flash.consume(req, secret)
        layout.page(
          req,
          secret,
          "Timeline",
          flash_opt,
          html.div([class("timeline-page")], [component]),
        )
      },
    ),
  )
  |> router.post("/logout", auth_ctrl.logout(repo, secret))
  |> router.get("/register", auth_ctrl.register(repo, secret))
  |> router.post("/register", auth_ctrl.register(repo, secret))
  |> router.get("/login", auth_ctrl.login(repo, secret))
  |> router.post("/login", auth_ctrl.login(repo, secret))
  |> router.post("/chirps", chirps_ctrl.create(repo, secret))
  |> router.get("/users/:username", fn(req, params) {
    profile_page(repo, req, params, secret)
  })
  |> router.scope("/static", [middleware.static_files(
    under: "/static",
    from: "priv/static",
  )], fn(s) {
    s |> router.get("/*", fn(_req, _params) { mw_response.not_found() })
  })
}

fn profile_page(
  repo: Repo,
  req: request.Request(Connection),
  params: List(#(String, String)),
  secret: String,
) -> response.Response(ResponseData) {
  let username = case mw_request.path_param(params, "username") {
    Some(u) -> u
    None -> ""
  }
  let #(flash_opt, clear_flash) = flash.consume(req, secret)
  case to_string_error(queries.user_by_username(repo, username)) {
    Error(_) ->
      mw_response.html(
        404,
        element.to_document_string(layout.page(
          req,
          secret,
          "Not Found",
          None,
          html.p([], [html.text("User @" <> username <> " not found.")]),
        )),
      )
    Ok(user) -> {
      let chirps = case to_string_error(queries.user_chirps(repo, user.id)) {
        Ok(cs) -> cs
        Error(_) -> []
      }
      let content =
        html.div([class("profile")], [
          html.div([class("profile-header")], [
            html.h1([class("profile-name")], [html.text("@" <> user.username)]),
            html.p([class("profile-email")], [html.text(user.email)]),
            html.p([class("profile-stats")], [
              html.text(int.to_string(list.length(chirps)) <> " chirps"),
            ]),
          ]),
          html.div(
            [class("chirp-list")],
            list.map(chirps, fn(c) {
              html.article([class("chirp-card")], [
                html.div([class("chirp-header")], [
                  html.span([class("chirp-time")], [html.text(c.inserted_at)]),
                ]),
                html.p([class("chirp-body")], [html.text(c.body)]),
              ])
            }),
          ),
        ])
      mw_response.html(
        200,
        element.to_document_string(
          layout.page(req, secret, "@" <> username, flash_opt, content),
        ),
      )
      |> clear_flash
    }
  }
}

fn to_string_error(r: Result(a, GlooError)) -> Result(a, String) {
  result.map_error(r, fn(_) { "db error" })
}
