# live

Mounts Lustre server-side components over a WebSocket connection.

## Functions

### `handler`
```gleam
pub fn handler(app: fn() -> App(flags, model, msg)) -> fn(Conn(Connection), Params) -> Response(ResponseData)
```
Mount a static LiveView. The app factory is called once per WebSocket connection.

---

### `dynamic_handler`
```gleam
pub fn dynamic_handler(make_app: fn(Conn(Connection), Params) -> App(flags, model, msg)) -> fn(Conn(Connection), Params) -> Response(ResponseData)
```
Mount a LiveView with per-request context. `make_app` receives the `Conn` and path params, enabling auth and other context to flow into the component.

---

### `dynamic_handler_with_shell`
```gleam
pub fn dynamic_handler_with_shell(
  make_app: fn(Conn(Connection), Params) -> App(flags, model, msg),
  shell: fn(Conn(Connection), Element(msg)) -> Response(ResponseData),
) -> fn(Conn(Connection), Params) -> Response(ResponseData)
```
Like `dynamic_handler` but wraps the initial render in a full-page `shell`. The shell receives the `Conn` (for layout/auth) and the rendered component element. Use this to wrap LiveView in your app's HTML layout.

## Example

```gleam
router.get(
  "/timeline",
  live.dynamic_handler_with_shell(
    fn(c, _params) { timeline.make(c.auth) },
    fn(c, component) {
      mw_response.html(200, element.to_document_string(
        layout.page(c, "Timeline", None, component),
      ))
    },
  ),
)
```
