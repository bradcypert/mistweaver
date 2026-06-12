# router

The core routing module. Builds a tree of routes and dispatches incoming requests to the correct handler.

## Types

```gleam
pub type Params = List(#(String, String))

pub type Handler(body) =
  fn(Conn(body), Params) -> Response(ResponseData)

pub type Middleware(body) =
  fn(Conn(body), fn(Conn(body)) -> Response(ResponseData)) -> Response(ResponseData)

pub opaque type Router(body)
```

## Functions

### `new`
```gleam
pub fn new() -> Router(body)
```
Create an empty router.

---

### `get` / `post` / `put` / `patch` / `delete` / `head` / `options`
```gleam
pub fn get(router: Router(body), path: String, handler: Handler(body)) -> Router(body)
pub fn post(router: Router(body), path: String, handler: Handler(body)) -> Router(body)
pub fn put(router: Router(body), path: String, handler: Handler(body)) -> Router(body)
pub fn patch(router: Router(body), path: String, handler: Handler(body)) -> Router(body)
pub fn delete(router: Router(body), path: String, handler: Handler(body)) -> Router(body)
pub fn head(router: Router(body), path: String, handler: Handler(body)) -> Router(body)
pub fn options(router: Router(body), path: String, handler: Handler(body)) -> Router(body)
```
Register a handler for the given method and path. Paths may contain `:param` segments or a trailing `*` wildcard.

---

### `scope`
```gleam
pub fn scope(
  router: Router(body),
  prefix: String,
  middleware: List(Middleware(body)),
  build: fn(Router(body)) -> Router(body),
) -> Router(body)
```
Group routes under a path prefix with shared middleware. Middleware runs outermost-first.

---

### `dispatch`
```gleam
pub fn dispatch(router: Router(body), req: Request(body)) -> Response(ResponseData)
```
Match a request against registered routes and call the handler. Returns 404 if no route matches.

---

### `to_handler`
```gleam
pub fn to_handler(router: Router(Connection)) -> fn(Request(Connection)) -> Response(ResponseData)
```
Convert a router into a plain handler function suitable for passing to `mist.new_handler`.
