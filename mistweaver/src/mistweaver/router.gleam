import gleam/bytes_tree
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/list
import gleam/string
import mist.{type Connection, type ResponseData}

/// Path parameters extracted from a matched route, e.g. [#("id", "42")].
pub type Params =
  List(#(String, String))

/// A handler receives the (possibly middleware-transformed) request and the
/// path params captured during route matching.
///
/// In production this is `Handler(Connection)`; in tests use any body type.
pub type Handler(body) =
  fn(Request(body), Params) -> Response(ResponseData)

/// Middleware wraps a handler: it receives the request and a `next` function
/// to call (with a possibly-modified request) to continue the chain.
/// Compose with Gleam's `use` syntax:
///
///   use req <- middleware.log(req)
pub type Middleware(body) =
  fn(Request(body), fn(Request(body)) -> Response(ResponseData)) ->
    Response(ResponseData)

pub opaque type PathSegment {
  Static(String)
  Param(String)
  Wildcard
}

pub opaque type Route(body) {
  Route(
    method: http.Method,
    segments: List(PathSegment),
    middlewares: List(Middleware(body)),
    handler: Handler(body),
  )
}

/// A compiled router. Parameterised over the request body type so that tests
/// can use `Router(Nil)` while production code uses `Router(Connection)`.
pub opaque type Router(body) {
  Router(
    routes: List(Route(body)),
    prefix: List(PathSegment),
    middlewares: List(Middleware(body)),
  )
}

pub fn new() -> Router(body) {
  Router(routes: [], prefix: [], middlewares: [])
}

pub fn get(
  router: Router(body),
  path: String,
  handler: Handler(body),
) -> Router(body) {
  add_route(router, http.Get, path, handler)
}

pub fn post(
  router: Router(body),
  path: String,
  handler: Handler(body),
) -> Router(body) {
  add_route(router, http.Post, path, handler)
}

pub fn put(
  router: Router(body),
  path: String,
  handler: Handler(body),
) -> Router(body) {
  add_route(router, http.Put, path, handler)
}

pub fn patch(
  router: Router(body),
  path: String,
  handler: Handler(body),
) -> Router(body) {
  add_route(router, http.Patch, path, handler)
}

pub fn delete(
  router: Router(body),
  path: String,
  handler: Handler(body),
) -> Router(body) {
  add_route(router, http.Delete, path, handler)
}

pub fn head(
  router: Router(body),
  path: String,
  handler: Handler(body),
) -> Router(body) {
  add_route(router, http.Head, path, handler)
}

pub fn options(
  router: Router(body),
  path: String,
  handler: Handler(body),
) -> Router(body) {
  add_route(router, http.Options, path, handler)
}

/// Group routes under a shared path prefix and middleware stack. Scopes nest:
/// middleware from an outer scope runs before the inner scope's middleware.
///
///   router.new()
///   |> router.scope("/api", [auth_middleware], fn(r) {
///     r
///     |> router.get("/users", users.index)
///     |> router.get("/users/:id", users.show)
///   })
pub fn scope(
  router: Router(body),
  prefix: String,
  middlewares: List(Middleware(body)),
  build: fn(Router(body)) -> Router(body),
) -> Router(body) {
  let prefix_segments = parse_path(prefix)
  let scoped =
    Router(
      routes: [],
      prefix: list.append(router.prefix, prefix_segments),
      middlewares: list.append(router.middlewares, middlewares),
    )
  let built = build(scoped)
  Router(..router, routes: list.append(router.routes, built.routes))
}

/// Dispatch an incoming request through the router. Returns 404 if no route
/// matches. A `Router(Connection)` is a valid Mist handler via partial apply:
///
///   mist.new(router.dispatch(my_router, _))
pub fn dispatch(
  router: Router(body),
  req: Request(body),
) -> Response(ResponseData) {
  let path_segments = parse_request_path(req)
  case match_route(router.routes, req.method, path_segments) {
    Ok(#(route, params)) ->
      apply_middlewares(route.middlewares, req, fn(req2) {
        route.handler(req2, params)
      })
    Error(Nil) -> not_found()
  }
}

/// Convenience alias for starting a Mist server directly from a router.
/// Equivalent to `mist.new(router.dispatch(r, _))`.
pub fn to_handler(
  r: Router(Connection),
) -> fn(Request(Connection)) -> Response(ResponseData) {
  dispatch(r, _)
}

fn add_route(
  router: Router(body),
  method: http.Method,
  path: String,
  handler: Handler(body),
) -> Router(body) {
  let route =
    Route(
      method: method,
      segments: list.append(router.prefix, parse_path(path)),
      middlewares: router.middlewares,
      handler: handler,
    )
  Router(..router, routes: list.append(router.routes, [route]))
}

fn parse_path(path: String) -> List(PathSegment) {
  path
  |> string.split("/")
  |> list.filter(fn(s) { s != "" })
  |> list.map(fn(segment) {
    case string.starts_with(segment, ":") {
      True -> Param(string.drop_start(segment, 1))
      False ->
        case segment {
          "*" -> Wildcard
          s -> Static(s)
        }
    }
  })
}

fn parse_request_path(req: Request(body)) -> List(String) {
  req.path
  |> string.split("/")
  |> list.filter(fn(s) { s != "" })
}

fn match_route(
  routes: List(Route(body)),
  method: http.Method,
  path_segments: List(String),
) -> Result(#(Route(body), Params), Nil) {
  case routes {
    [] -> Error(Nil)
    [route, ..rest] ->
      case route.method == method {
        False -> match_route(rest, method, path_segments)
        True ->
          case match_segments(route.segments, path_segments, []) {
            Ok(params) -> Ok(#(route, params))
            Error(Nil) -> match_route(rest, method, path_segments)
          }
      }
  }
}

fn match_segments(
  route: List(PathSegment),
  request: List(String),
  acc: Params,
) -> Result(Params, Nil) {
  case route, request {
    [], [] -> Ok(list.reverse(acc))
    [Wildcard, ..], _ -> Ok(list.reverse(acc))
    [], _ -> Error(Nil)
    _, [] -> Error(Nil)
    [Static(expected), ..route_rest], [actual, ..req_rest] ->
      case expected == actual {
        True -> match_segments(route_rest, req_rest, acc)
        False -> Error(Nil)
      }
    [Param(name), ..route_rest], [value, ..req_rest] ->
      match_segments(route_rest, req_rest, [#(name, value), ..acc])
  }
}

fn apply_middlewares(
  middlewares: List(Middleware(body)),
  req: Request(body),
  final: fn(Request(body)) -> Response(ResponseData),
) -> Response(ResponseData) {
  case middlewares {
    [] -> final(req)
    [middleware, ..rest] ->
      middleware(req, fn(req2) { apply_middlewares(rest, req2, final) })
  }
}

fn not_found() -> Response(ResponseData) {
  response.new(404)
  |> response.set_body(mist.Bytes(bytes_tree.new()))
}
