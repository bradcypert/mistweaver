# LiveView

Mistweaver integrates [Lustre](https://lustre.build) server-side components over a WebSocket connection. The server holds state and pushes HTML diffs; the client applies them with a small JS runtime.

## Defining a LiveView

A LiveView is a standard Lustre `App`. Define `init`, `update`, and `view`:

```gleam
import lustre
import lustre/element.{type Element}
import lustre/element/html

pub type Model { Model(count: Int) }
pub type Msg { Increment | Decrement }

pub fn init(_flags) -> #(Model, lustre.Effect(Msg)) {
  #(Model(count: 0), lustre.none())
}

pub fn update(model: Model, msg: Msg) -> #(Model, lustre.Effect(Msg)) {
  case msg {
    Increment -> #(Model(count: model.count + 1), lustre.none())
    Decrement -> #(Model(count: model.count - 1), lustre.none())
  }
}

pub fn view(model: Model) -> Element(Msg) {
  html.div([], [
    html.button([event.on_click(Decrement)], [html.text("-")]),
    html.span([], [html.text(int.to_string(model.count))]),
    html.button([event.on_click(Increment)], [html.text("+")]),
  ])
}
```

## Mounting with auth context

Use `live.dynamic_handler_with_shell` to inject `conn` context (including auth) into the component factory:

```gleam
router.get(
  "/counter",
  live.dynamic_handler_with_shell(
    fn(c, _params) { counter.make(c.auth) },
    fn(c, component) {
      mw_response.html(200, element.to_document_string(
        layout.page(c, "Counter", None, component),
      ))
    },
  ),
)
```

`make` returns a `lustre.ServerComponent` built from the context:

```gleam
pub fn make(auth: Option(AuthUser)) -> lustre.App(...) {
  lustre.component(
    fn(_) { init(option.map(auth, fn(u) { u.id })) },
    update,
    view,
    dict.new(),
  )
}
```

## PubSub integration

LiveView components can subscribe to PubSub topics and push updates to connected clients. Subscribe in `init` and handle messages with a Lustre effect that sends to `process.self()`.
