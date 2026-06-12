import gleam/option.{None, Some}
import lustre/attribute.{attribute, class, href, type_}
import lustre/element.{type Element}
import lustre/element/html
import lustre/server_component
import mist.{type Connection}
import mistweaver/conn.{type Conn}
import mistweaver/flash.{type Flash}

/// Full page shell. Reads auth from conn so no session re-parse is needed.
pub fn page(
  conn: Conn(Connection),
  title: String,
  flash_opt: option.Option(Flash),
  content: Element(Nil),
) -> Element(Nil) {
  let logged_in_as = conn.auth |> option.map(fn(u) { u.username })

  html.html([attribute("lang", "en")], [
    html.head([], [
      html.meta([attribute("charset", "utf-8")]),
      html.meta([
        attribute("name", "viewport"),
        attribute("content", "width=device-width, initial-scale=1"),
      ]),
      html.title([], "Chirp — " <> title),
      server_component.script(),
      html.link([attribute("rel", "stylesheet"), href("/static/app.css")]),
    ]),
    html.body([], [
      html.nav([class("nav")], [
        html.a([href("/"), class("nav-brand")], [html.text("🐦 Chirp")]),
        html.div([class("nav-links")], case logged_in_as {
          Some(username) -> [
            html.span([class("nav-user")], [html.text("@" <> username)]),
            html.form(
              [attribute("method", "POST"), attribute("action", "/logout")],
              [
                html.button([type_("submit"), class("btn-link")], [
                  html.text("Sign out"),
                ]),
              ],
            ),
          ]
          None -> [
            html.a([href("/login"), class("nav-link")], [html.text("Sign in")]),
            html.a([href("/register"), class("nav-link btn-primary")], [
              html.text("Join"),
            ]),
          ]
        }),
      ]),
      case flash_opt {
        Some(f) ->
          html.div([class("flash flash-" <> f.kind)], [html.text(f.message)])
        None -> html.text("")
      },
      html.main([class("main")], [content]),
    ]),
  ])
}
