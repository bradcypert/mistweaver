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
import mistweaver/auth
import mistweaver/conn.{type Conn}
import mistweaver/flash
import mistweaver/live
import mistweaver/middleware
import mistweaver/request as mw_request
import mistweaver/response as mw_response
import mistweaver/router
import chirp/controllers/auth as auth_ctrl
import chirp/controllers/chirps as chirps_ctrl
import chirp/layout
import chirp/live/timeline
import chirp/queries

pub fn build(repo: Repo, secret: String) -> router.Router(Connection) {
  router.new()
  |> router.scope("/", [auth.load(secret)], fn(r) {
    r
    |> router.get("/", fn(c, _) {
      case c.auth {
        Some(_) -> mw_response.redirect(302, to: "/timeline")
        None -> mw_response.redirect(302, to: "/login")
      }
    })
    |> router.get("/register", auth_ctrl.register(repo, secret))
    |> router.post("/register", auth_ctrl.register(repo, secret))
    |> router.get("/login", auth_ctrl.login(repo, secret))
    |> router.post("/login", auth_ctrl.login(repo, secret))
    |> router.get("/users/:username", fn(c, params) {
      profile_page(repo, c, params, secret)
    })
    |> router.scope("/", [auth.require(secret, to: "/login")], fn(r2) {
      r2
      |> router.get(
        "/timeline",
        live.dynamic_handler_with_shell(
          fn(c, _params) { timeline.make(repo, c.auth) },
          fn(c, component) {
            let #(flash_opt, clear_flash) = flash.consume(c.request, secret)
            mw_response.html(
              200,
              element.to_document_string(
                layout.page(
                  c,
                  "Timeline",
                  flash_opt,
                  html.div([class("timeline-page")], [component]),
                ),
              ),
            )
            |> clear_flash
          },
        ),
      )
      |> router.post("/chirps", chirps_ctrl.create(repo, secret))
      |> router.post("/logout", auth_ctrl.logout(secret))
    })
  })
  |> router.scope("/static", [middleware.static_files(
    under: "/static",
    from: "priv/static",
  )], fn(s) {
    s |> router.get("/*", fn(_c, _params) { mw_response.not_found() })
  })
}

fn profile_page(
  repo: Repo,
  c: Conn(Connection),
  params: List(#(String, String)),
  secret: String,
) -> response.Response(ResponseData) {
  let username = case mw_request.path_param(params, "username") {
    Some(u) -> u
    None -> ""
  }
  let #(flash_opt, clear_flash) = flash.consume(c.request, secret)
  case to_string_error(queries.user_by_username(repo, username)) {
    Error(_) ->
      mw_response.html(
        404,
        element.to_document_string(
          layout.page(
            c,
            "Not Found",
            None,
            html.p([], [html.text("User @" <> username <> " not found.")]),
          ),
        ),
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
            list.map(chirps, fn(ch) {
              html.article([class("chirp-card")], [
                html.div([class("chirp-header")], [
                  html.span([class("chirp-time")], [html.text(ch.inserted_at)]),
                ]),
                html.p([class("chirp-body")], [html.text(ch.body)]),
              ])
            }),
          ),
        ])
      mw_response.html(
        200,
        element.to_document_string(
          layout.page(c, "@" <> username, flash_opt, content),
        ),
      )
      |> clear_flash
    }
  }
}

fn to_string_error(r: Result(a, GlooError)) -> Result(a, String) {
  result.map_error(r, fn(_) { "db error" })
}
