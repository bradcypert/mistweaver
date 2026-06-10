import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/server_component
import mist.{type Connection, type ResponseData}
import mistweaver/response as mw_response

// ---------------------------------------------------------------------------
// Public types
// ---------------------------------------------------------------------------

/// The three callbacks that define a LiveView. Mirrors Lustre's MVU model but
/// is initiated with the URL path params (so you can load data from them).
///
///   let counter_live = live.LiveView(
///     init: fn(_params) { #(0, effect.none()) },
///     update: fn(count, msg) {
///       case msg {
///         Inc -> #(count + 1, effect.none())
///         Dec -> #(count - 1, effect.none())
///       }
///     },
///     view: fn(count) {
///       html.div([], [
///         html.button([event.on_click(Dec)], [html.text("-")]),
///         html.p([], [html.text(int.to_string(count))]),
///         html.button([event.on_click(Inc)], [html.text("+")]),
///       ])
///     },
///   )
pub type LiveView(model, msg) {
  LiveView(
    init: fn(List(#(String, String))) -> #(model, Effect(msg)),
    update: fn(model, msg) -> #(model, Effect(msg)),
    view: fn(model) -> Element(msg),
  )
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Return a route handler for a LiveView. A single handler manages both the
/// initial page request and the WebSocket upgrade:
///
/// - Regular HTTP GET → serves an HTML shell embedding the Lustre client
///   runtime and a `<lustre-server-component>` element wired to this same URL.
/// - WebSocket upgrade → starts a Lustre server component runtime for this
///   connection and bridges Mist WebSocket messages to/from the Lustre runtime.
///
///   router.new()
///   |> router.get("/counter", live.handler(counter_live))
///   |> router.get("/counter/*", live.handler(counter_live))
pub fn handler(
  lv: LiveView(model, msg),
) -> fn(Request(Connection), List(#(String, String))) -> Response(ResponseData) {
  fn(req, params) {
    case request.get_header(req, "upgrade") {
      Ok("websocket") -> ws_upgrade(lv, req, params)
      _ -> serve_shell(req)
    }
  }
}

/// Like `handler/1` but lets the caller supply the full HTML shell.
/// The `shell` function receives the request and the pre-built
/// `<lustre-server-component>` element; it must include
/// `server_component.script()` somewhere in `<head>`.
///
/// This lets you wrap the live component in a page layout with navigation,
/// forms, or other static content — including session-aware content since the
/// request (and its cookies) is available.
///
///   router.get("/timeline", live.handler_with_shell(timeline_live, fn(req, component) {
///     layout(req, component)
///   }))
pub fn handler_with_shell(
  lv: LiveView(model, msg),
  shell: fn(Request(Connection), Element(Nil)) -> Element(Nil),
) -> fn(Request(Connection), List(#(String, String))) -> Response(ResponseData) {
  fn(req, params) {
    case request.get_header(req, "upgrade") {
      Ok("websocket") -> ws_upgrade(lv, req, params)
      _ -> serve_custom_shell(req, shell)
    }
  }
}

fn serve_custom_shell(
  req: Request(Connection),
  shell: fn(Request(Connection), Element(Nil)) -> Element(Nil),
) -> Response(ResponseData) {
  let component =
    server_component.element(
      [
        server_component.route(req.path <> case req.query {
          Some(q) -> "?" <> q
          None -> ""
        }),
        server_component.method(server_component.WebSocket),
      ],
      [],
    )
  mw_response.html(200, element.to_document_string(shell(req, component)))
}

/// Like `handler/1` but the LiveView is created fresh per request by calling
/// `make_lv(req, params)`. This lets the LiveView's `init` and `update`
/// functions close over session data (or any other per-request context)
/// extracted from the request — analogous to Phoenix `mount/3` receiving
/// the socket with session assigns.
///
///   router.get("/timeline", live.dynamic_handler(fn(req, _params) {
///     let sess  = session.get(req, secret)
///     let uid   = session.fetch(sess, "user_id") |> option.then(int.parse >> option.from_result)
///     timeline.make(repo, uid)
///   }))
pub fn dynamic_handler(
  make_lv: fn(Request(Connection), List(#(String, String))) -> LiveView(
    model,
    msg,
  ),
) -> fn(Request(Connection), List(#(String, String))) -> Response(ResponseData) {
  fn(req, params) {
    case request.get_header(req, "upgrade") {
      Ok("websocket") -> ws_upgrade(make_lv(req, params), req, params)
      _ -> serve_shell(req)
    }
  }
}

/// `dynamic_handler` with a custom HTML shell. Both the LiveView factory and
/// the shell receive the full request, so both can read the session.
pub fn dynamic_handler_with_shell(
  make_lv: fn(Request(Connection), List(#(String, String))) -> LiveView(
    model,
    msg,
  ),
  shell: fn(Request(Connection), Element(Nil)) -> Element(Nil),
) -> fn(Request(Connection), List(#(String, String))) -> Response(ResponseData) {
  fn(req, params) {
    case request.get_header(req, "upgrade") {
      Ok("websocket") -> ws_upgrade(make_lv(req, params), req, params)
      _ -> serve_custom_shell(req, shell)
    }
  }
}

// ---------------------------------------------------------------------------
// HTML shell
// ---------------------------------------------------------------------------

fn serve_shell(req: Request(Connection)) -> Response(ResponseData) {
  let page =
    html.html([attribute.attribute("lang", "en")], [
      html.head([], [
        html.meta([attribute.attribute("charset", "utf-8")]),
        html.meta([
          attribute.attribute("name", "viewport"),
          attribute.attribute(
            "content",
            "width=device-width, initial-scale=1",
          ),
        ]),
        server_component.script(),
      ]),
      html.body([], [
        server_component.element(
          [
            server_component.route(req.path),
            server_component.method(server_component.WebSocket),
          ],
          [],
        ),
      ]),
    ])

  mw_response.html(200, element.to_document_string(page))
}

// ---------------------------------------------------------------------------
// WebSocket bridge
// ---------------------------------------------------------------------------

fn ws_upgrade(
  lv: LiveView(model, msg),
  req: Request(Connection),
  params: List(#(String, String)),
) -> Response(ResponseData) {
  mist.websocket(
    request: req,
    handler: fn(state, msg, conn) { handle_ws(state, msg, conn) },
    on_init: fn(_conn) {
      let app = lustre.application(lv.init, lv.update, lv.view)
      let query_params =
        request.get_query(req) |> result.unwrap([])
      let all_params = list.append(params, query_params)
      case lustre.start_server_component(app, all_params) {
        Ok(runtime) -> {
          let runtime_subj = server_component.subject(runtime)
          let client_subj = process.new_subject()

          process.send(
            runtime_subj,
            server_component.register_subject(client_subj),
          )

          let selector =
            process.new_selector()
            |> process.select(for: client_subj)

          #(runtime_subj, Some(selector))
        }
        Error(_) -> {
          // Couldn't start the runtime — return a dummy state that will
          // immediately stop when any message arrives.
          let dummy = process.new_subject()
          #(dummy, None)
        }
      }
    },
    on_close: fn(runtime_subj) {
      process.send(runtime_subj, lustre.shutdown())
    },
  )
}

fn handle_ws(
  runtime_subj: process.Subject(lustre.RuntimeMessage(msg)),
  msg: mist.WebsocketMessage(server_component.ClientMessage(msg)),
  conn: mist.WebsocketConnection,
) -> mist.Next(process.Subject(lustre.RuntimeMessage(msg)), server_component.ClientMessage(msg)) {
  case msg {
    mist.Text(data) -> {
      let _ =
        json.parse(data, server_component.runtime_message_decoder())
        |> result.map(fn(runtime_msg) {
          process.send(runtime_subj, runtime_msg)
        })
      mist.continue(runtime_subj)
    }

    mist.Custom(client_msg) -> {
      let payload =
        client_msg
        |> server_component.client_message_to_json
        |> json.to_string
      let _ = mist.send_text_frame(conn, payload)
      mist.continue(runtime_subj)
    }

    mist.Closed | mist.Shutdown -> {
      process.send(runtime_subj, lustre.shutdown())
      mist.stop()
    }

    mist.Binary(_) -> mist.continue(runtime_subj)
  }
}
