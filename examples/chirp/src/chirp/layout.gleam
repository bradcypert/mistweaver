import gleam/http/request.{type Request}
import gleam/option.{None, Some}
import lustre/attribute.{attribute, class, href, type_}
import lustre/element.{type Element}
import lustre/element/html
import lustre/server_component
import mist.{type Connection}
import mistweaver/flash.{type Flash}
import mistweaver/session

/// Full page shell. `flash_opt` is rendered as a banner above main content.
pub fn page(
  req: Request(Connection),
  secret: String,
  title: String,
  flash_opt: option.Option(Flash),
  content: Element(Nil),
) -> Element(Nil) {
  let sess = session.get(req, secret)
  let logged_in_as = session.fetch(sess, "username")

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
