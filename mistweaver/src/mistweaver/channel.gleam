import gleam/bit_array
import gleam/crypto
import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import mist.{
  type Connection, type ResponseData, type WebsocketConnection,
  type WebsocketMessage,
}

// ---------------------------------------------------------------------------
// Public types
// ---------------------------------------------------------------------------

/// Per-connection context passed to every channel callback.
pub type Socket {
  Socket(
    /// A unique opaque ID for this WebSocket connection.
    id: String,
    /// The topic this channel was joined on, e.g. `"room:lobby"`.
    topic: String,
    /// The join ref sent by the client when this topic was joined.
    join_ref: Option(String),
  )
}

/// A server-to-client push message.
pub type Push {
  /// Push a custom event with a JSON payload to the client.
  Event(event: String, payload: json.Json)
}

/// Callbacks that define a channel's behaviour. `state` is the user-defined
/// channel state (analogous to a GenServer's state in Phoenix).
///
///   let room_channel = channel.Channel(
///     join: fn(socket) { Ok(RoomState(members: [])) },
///     handle_in: fn(event, payload, state, socket) {
///       #(state, [channel.Event("new_msg", json.string("hello"))])
///     },
///     handle_close: fn(state, socket) { Nil },
///   )
pub type Channel(state) {
  Channel(
    /// Called when a client joins the topic. Return `Ok(state)` to accept or
    /// `Error(reason)` to reject.
    join: fn(Socket) -> Result(state, String),
    /// Called for every client-sent event on a joined topic. The `Dynamic`
    /// payload can be decoded with `gleam/dynamic/decode`.
    handle_in: fn(String, Dynamic, state, Socket) -> #(state, List(Push)),
    /// Called when the client leaves or the connection drops.
    handle_close: fn(state, Socket) -> Nil,
  )
}

/// A router that maps topic patterns to channel handlers.
///
///   channel.new_socket_router()
///   |> channel.route("room:*", room_channel)
///   |> channel.route("system:lobby", system_channel)
pub opaque type SocketRouter {
  SocketRouter(entries: List(SocketRouterEntry))
}

// ---------------------------------------------------------------------------
// Internal types
// ---------------------------------------------------------------------------

type TopicPattern {
  Exact(String)
  /// Matches any topic string that starts with `prefix`.
  Wildcard(prefix: String)
}

type SocketRouterEntry {
  SocketRouterEntry(
    pattern: TopicPattern,
    factory: fn(Socket) -> Result(BoundChannel, String),
  )
}

/// A type-erased channel whose state is captured in closures. This lets us
/// store heterogeneous channel types in the same collection.
type BoundChannel {
  BoundChannel(
    handle_in: fn(String, Dynamic, Socket) -> #(BoundChannel, List(Push)),
    handle_close: fn(Socket) -> Nil,
  )
}

type WsState {
  WsState(
    router: SocketRouter,
    /// Active channels for this connection, keyed by joined topic.
    channels: Dict(String, BoundChannel),
    id: String,
  )
}

type PhoenixMessage {
  PhoenixMessage(
    join_ref: Option(String),
    ref: Option(String),
    topic: String,
    event: String,
    payload: Dynamic,
  )
}

// ---------------------------------------------------------------------------
// SocketRouter API
// ---------------------------------------------------------------------------

pub fn new_socket_router() -> SocketRouter {
  SocketRouter(entries: [])
}

/// Register a channel for a topic pattern. Use `"topic:*"` to match any
/// subtopic, e.g. `"room:*"` matches `"room:lobby"` and `"room:123"`.
pub fn route(
  router: SocketRouter,
  pattern: String,
  ch: Channel(state),
) -> SocketRouter {
  let parsed = parse_pattern(pattern)
  let entry =
    SocketRouterEntry(
      pattern: parsed,
      factory: fn(socket) {
        case ch.join(socket) {
          Ok(state) -> Ok(bind(ch, state))
          Error(msg) -> Error(msg)
        }
      },
    )
  SocketRouter(entries: list.append(router.entries, [entry]))
}

/// Produce a Mistweaver route handler that upgrades HTTP to WebSocket and
/// runs the socket router. Wire it up with any HTTP method (conventionally GET):
///
///   router.new()
///   |> router.get("/socket/websocket", channel.handler(my_socket_router))
pub fn handler(
  socket_router: SocketRouter,
) -> fn(Request(Connection), List(#(String, String))) -> Response(ResponseData) {
  fn(req, _params) {
    mist.websocket(
      request: req,
      handler: handle_ws_message,
      on_init: fn(_conn) {
        let state =
          WsState(
            router: socket_router,
            channels: dict.new(),
            id: generate_socket_id(),
          )
        #(state, None)
      },
      on_close: fn(state) {
        dict.each(state.channels, fn(topic, bound) {
          let socket = Socket(id: state.id, topic: topic, join_ref: None)
          bound.handle_close(socket)
        })
      },
    )
  }
}

// ---------------------------------------------------------------------------
// WebSocket actor
// ---------------------------------------------------------------------------

fn handle_ws_message(
  state: WsState,
  msg: WebsocketMessage(Nil),
  conn: WebsocketConnection,
) -> mist.Next(WsState, Nil) {
  case msg {
    mist.Text(text) -> {
      case parse_message(text) {
        Ok(phoenix_msg) -> mist.continue(dispatch(state, phoenix_msg, conn))
        Error(_) -> mist.continue(state)
      }
    }
    mist.Binary(_) -> mist.continue(state)
    mist.Closed | mist.Shutdown -> mist.stop()
    mist.Custom(_) -> mist.continue(state)
  }
}

fn dispatch(
  state: WsState,
  msg: PhoenixMessage,
  conn: WebsocketConnection,
) -> WsState {
  case msg.topic, msg.event {
    "phoenix", "heartbeat" -> {
      send_reply(conn, None, msg.ref, "phoenix", "ok", json.object([]))
      state
    }

    _, "phx_join" -> {
      let socket =
        Socket(id: state.id, topic: msg.topic, join_ref: msg.join_ref)
      case find_channel(state.router.entries, msg.topic) {
        Ok(factory) -> {
          case factory(socket) {
            Ok(bound) -> {
              send_reply(
                conn,
                msg.join_ref,
                msg.ref,
                msg.topic,
                "ok",
                json.object([]),
              )
              WsState(
                ..state,
                channels: dict.insert(state.channels, msg.topic, bound),
              )
            }
            Error(reason) -> {
              send_reply(
                conn,
                msg.join_ref,
                msg.ref,
                msg.topic,
                "error",
                json.object([#("reason", json.string(reason))]),
              )
              state
            }
          }
        }
        Error(Nil) -> {
          send_reply(
            conn,
            msg.join_ref,
            msg.ref,
            msg.topic,
            "error",
            json.object([#("reason", json.string("no channel for topic"))]),
          )
          state
        }
      }
    }

    _, "phx_leave" -> {
      case dict.get(state.channels, msg.topic) {
        Ok(bound) -> {
          let socket =
            Socket(id: state.id, topic: msg.topic, join_ref: msg.join_ref)
          bound.handle_close(socket)
          send_reply(
            conn,
            msg.join_ref,
            msg.ref,
            msg.topic,
            "ok",
            json.object([]),
          )
          WsState(
            ..state,
            channels: dict.delete(state.channels, msg.topic),
          )
        }
        Error(Nil) -> state
      }
    }

    _, custom_event -> {
      case dict.get(state.channels, msg.topic) {
        Ok(bound) -> {
          let socket =
            Socket(id: state.id, topic: msg.topic, join_ref: msg.join_ref)
          let #(new_bound, pushes) =
            bound.handle_in(custom_event, msg.payload, socket)
          list.each(pushes, fn(push) {
            case push {
              Event(event, payload) ->
                send_push(conn, msg.topic, event, payload)
            }
          })
          WsState(
            ..state,
            channels: dict.insert(state.channels, msg.topic, new_bound),
          )
        }
        Error(Nil) -> state
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Phoenix protocol codec
// ---------------------------------------------------------------------------

fn parse_message(text: String) -> Result(PhoenixMessage, Nil) {
  json.parse(text, phoenix_message_decoder())
  |> result.replace_error(Nil)
}

fn phoenix_message_decoder() -> decode.Decoder(PhoenixMessage) {
  use join_ref <- decode.then(decode.at([0], decode.optional(decode.string)))
  use ref <- decode.then(decode.at([1], decode.optional(decode.string)))
  use topic <- decode.then(decode.at([2], decode.string))
  use event <- decode.then(decode.at([3], decode.string))
  use payload <- decode.then(decode.at([4], decode.dynamic))
  decode.success(PhoenixMessage(join_ref:, ref:, topic:, event:, payload:))
}

fn encode_message(
  join_ref: Option(String),
  ref: Option(String),
  topic: String,
  event: String,
  payload: json.Json,
) -> String {
  json.preprocessed_array([
    nullable_string(join_ref),
    nullable_string(ref),
    json.string(topic),
    json.string(event),
    payload,
  ])
  |> json.to_string
}

fn send_reply(
  conn: WebsocketConnection,
  join_ref: Option(String),
  ref: Option(String),
  topic: String,
  status: String,
  response: json.Json,
) -> Nil {
  let payload =
    json.object([
      #("status", json.string(status)),
      #("response", response),
    ])
  let text = encode_message(join_ref, ref, topic, "phx_reply", payload)
  let _ = mist.send_text_frame(conn, text)
  Nil
}

fn send_push(
  conn: WebsocketConnection,
  topic: String,
  event: String,
  payload: json.Json,
) -> Nil {
  let text = encode_message(None, None, topic, event, payload)
  let _ = mist.send_text_frame(conn, text)
  Nil
}

fn nullable_string(opt: Option(String)) -> json.Json {
  case opt {
    Some(s) -> json.string(s)
    None -> json.null()
  }
}

// ---------------------------------------------------------------------------
// Topic pattern matching
// ---------------------------------------------------------------------------

fn parse_pattern(pattern: String) -> TopicPattern {
  case string.ends_with(pattern, ":*") {
    True -> Wildcard(string.drop_end(pattern, 1))
    False ->
      case string.ends_with(pattern, "*") {
        True -> Wildcard(string.drop_end(pattern, 1))
        False -> Exact(pattern)
      }
  }
}

fn find_channel(
  entries: List(SocketRouterEntry),
  topic: String,
) -> Result(fn(Socket) -> Result(BoundChannel, String), Nil) {
  case entries {
    [] -> Error(Nil)
    [entry, ..rest] ->
      case matches_pattern(entry.pattern, topic) {
        True -> Ok(entry.factory)
        False -> find_channel(rest, topic)
      }
  }
}

fn matches_pattern(pattern: TopicPattern, topic: String) -> Bool {
  case pattern {
    Exact(p) -> p == topic
    Wildcard(prefix) -> string.starts_with(topic, prefix)
  }
}

// ---------------------------------------------------------------------------
// State binding — erases the `state` type parameter into closures
// ---------------------------------------------------------------------------

fn bind(ch: Channel(state), state: state) -> BoundChannel {
  BoundChannel(
    handle_in: fn(event, payload, socket) {
      let #(new_state, pushes) = ch.handle_in(event, payload, state, socket)
      #(bind(ch, new_state), pushes)
    },
    handle_close: fn(socket) { ch.handle_close(state, socket) },
  )
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

fn generate_socket_id() -> String {
  crypto.strong_random_bytes(8)
  |> bit_array.base16_encode
  |> string.lowercase
}
