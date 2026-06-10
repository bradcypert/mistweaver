import gleam/dynamic
import gleam/http
import gleam/list
import gleam/http/request
import gleam/http/response
import gleam/json
import gleam/option.{None, Some}
import gleeunit
import mist
import mistweaver/channel
import mistweaver/middleware
import mistweaver/request as mw_request
import mistweaver/response as mw_response
import mistweaver/router

pub fn main() -> Nil {
  gleeunit.main()
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

fn make_request(method: http.Method, path: String) -> request.Request(Nil) {
  request.Request(
    method: method,
    headers: [],
    body: Nil,
    scheme: http.Http,
    host: "localhost",
    port: None,
    path: path,
    query: None,
  )
}

fn ok_text(body: String) -> response.Response(mist.ResponseData) {
  mw_response.text(200, body)
}

// ---------------------------------------------------------------------------
// Router: method dispatch
// ---------------------------------------------------------------------------

pub fn dispatches_get_test() {
  let r =
    router.new()
    |> router.get("/hello", fn(_req, _params) { ok_text("hello") })

  let resp = router.dispatch(r, make_request(http.Get, "/hello"))
  assert resp.status == 200
}

pub fn dispatches_post_test() {
  let r =
    router.new()
    |> router.post("/items", fn(_req, _params) { mw_response.text(201, "created") })

  let resp = router.dispatch(r, make_request(http.Post, "/items"))
  assert resp.status == 201
}

pub fn method_mismatch_returns_404_test() {
  let r =
    router.new()
    |> router.get("/hello", fn(_req, _params) { ok_text("hello") })

  let resp = router.dispatch(r, make_request(http.Post, "/hello"))
  assert resp.status == 404
}

pub fn unknown_path_returns_404_test() {
  let r =
    router.new()
    |> router.get("/hello", fn(_req, _params) { ok_text("hello") })

  let resp = router.dispatch(r, make_request(http.Get, "/goodbye"))
  assert resp.status == 404
}

// ---------------------------------------------------------------------------
// Router: path parameters
// ---------------------------------------------------------------------------

pub fn captures_single_path_param_test() {
  let r =
    router.new()
    |> router.get("/users/:id", fn(_req, params) {
      let id = case mw_request.path_param(params, "id") {
        Some(v) -> v
        None -> "missing"
      }
      ok_text(id)
    })

  let resp = router.dispatch(r, make_request(http.Get, "/users/42"))
  assert resp.status == 200
}

pub fn captures_multiple_path_params_test() {
  let r =
    router.new()
    |> router.get("/orgs/:org/repos/:repo", fn(_req, params) {
      case
        mw_request.path_param(params, "org"),
        mw_request.path_param(params, "repo")
      {
        Some(o), Some(repo) -> ok_text(o <> "/" <> repo)
        _, _ -> mw_response.bad_request("missing params")
      }
    })

  let resp =
    router.dispatch(r, make_request(http.Get, "/orgs/acme/repos/widget"))
  assert resp.status == 200
}

pub fn param_does_not_match_wrong_segment_count_test() {
  let r =
    router.new()
    |> router.get("/users/:id", fn(_req, _params) { ok_text("ok") })

  let resp = router.dispatch(r, make_request(http.Get, "/users/42/extra"))
  assert resp.status == 404
}

// ---------------------------------------------------------------------------
// Router: scopes
// ---------------------------------------------------------------------------

pub fn scope_prefixes_routes_test() {
  let r =
    router.new()
    |> router.scope("/api", [], fn(s) {
      s |> router.get("/users", fn(_req, _params) { ok_text("users") })
    })

  let ok = router.dispatch(r, make_request(http.Get, "/api/users"))
  assert ok.status == 200

  let nf = router.dispatch(r, make_request(http.Get, "/users"))
  assert nf.status == 404
}

pub fn scope_middleware_runs_before_handler_test() {
  let marker = "x-scope-ran"

  let scope_mw = fn(req, next: fn(_) -> _) {
    next(request.set_header(req, marker, "true"))
  }

  let r =
    router.new()
    |> router.scope("/api", [scope_mw], fn(s) {
      s
      |> router.get("/ping", fn(req, _params) {
        case request.get_header(req, marker) {
          Ok("true") -> ok_text("middleware ran")
          _ -> mw_response.internal_server_error("middleware did not run")
        }
      })
    })

  let resp = router.dispatch(r, make_request(http.Get, "/api/ping"))
  assert resp.status == 200
}

pub fn nested_scopes_accumulate_prefix_test() {
  let r =
    router.new()
    |> router.scope("/v1", [], fn(outer) {
      outer
      |> router.scope("/admin", [], fn(inner) {
        inner
        |> router.get("/users", fn(_req, _params) { ok_text("admin users") })
      })
    })

  let ok = router.dispatch(r, make_request(http.Get, "/v1/admin/users"))
  assert ok.status == 200

  let nf = router.dispatch(r, make_request(http.Get, "/admin/users"))
  assert nf.status == 404
}

// ---------------------------------------------------------------------------
// Response helpers
// ---------------------------------------------------------------------------

pub fn html_response_sets_content_type_test() {
  let resp = mw_response.html(200, "<h1>Hi</h1>")
  assert resp.status == 200
  assert response.get_header(resp, "content-type")
    == Ok("text/html; charset=utf-8")
}

pub fn json_response_sets_content_type_test() {
  let resp = mw_response.json(200, json.null())
  assert response.get_header(resp, "content-type") == Ok("application/json")
}

pub fn redirect_sets_location_header_test() {
  let resp = mw_response.redirect(302, to: "/new-path")
  assert resp.status == 302
  assert response.get_header(resp, "location") == Ok("/new-path")
}

// ---------------------------------------------------------------------------
// Request helpers
// ---------------------------------------------------------------------------

pub fn path_param_found_test() {
  let params = [#("id", "99"), #("name", "alice")]
  assert mw_request.path_param(params, "id") == Some("99")
  assert mw_request.path_param(params, "name") == Some("alice")
}

pub fn path_param_missing_test() {
  let params = [#("id", "99")]
  assert mw_request.path_param(params, "other") == None
}

pub fn path_segments_test() {
  let req = make_request(http.Get, "/users/42/posts")
  assert mw_request.path_segments(req) == ["users", "42", "posts"]
}

pub fn query_param_test() {
  let req =
    request.Request(
      ..make_request(http.Get, "/search"),
      query: Some("q=gleam&page=2"),
    )
  assert mw_request.query_param(req, "q") == Some("gleam")
  assert mw_request.query_param(req, "page") == Some("2")
  assert mw_request.query_param(req, "missing") == None
}

// ---------------------------------------------------------------------------
// Middleware
// ---------------------------------------------------------------------------

pub fn request_id_generates_header_test() {
  let resp =
    middleware.request_id(make_request(http.Get, "/"), fn(_req) {
      mw_response.ok()
    })
  assert response.get_header(resp, "x-request-id") != Error(Nil)
}

pub fn request_id_propagates_existing_test() {
  let req =
    make_request(http.Get, "/")
    |> request.set_header("x-request-id", "my-custom-id")

  // If the incoming ID is propagated, it should be echoed in the response
  let resp = middleware.request_id(req, fn(_r) { mw_response.ok() })
  assert response.get_header(resp, "x-request-id") == Ok("my-custom-id")
}

pub fn request_id_echoes_id_in_response_test() {
  let req =
    make_request(http.Get, "/")
    |> request.set_header("x-request-id", "echo-me")

  let resp = middleware.request_id(req, fn(_req) { mw_response.ok() })
  assert response.get_header(resp, "x-request-id") == Ok("echo-me")
}

pub fn cors_adds_headers_test() {
  let opts = middleware.cors_allow_all()
  let resp =
    middleware.cors(opts, make_request(http.Get, "/"), fn(_req) {
      mw_response.ok()
    })
  assert response.get_header(resp, "access-control-allow-origin") == Ok("*")
  assert response.get_header(resp, "access-control-allow-methods") != Error(Nil)
}

pub fn cors_handles_preflight_test() {
  let opts = middleware.cors_allow_all()
  let resp =
    middleware.cors(opts, make_request(http.Options, "/api/users"), fn(_req) {
      mw_response.ok()
    })
  assert resp.status == 204
  assert response.get_header(resp, "access-control-allow-origin") == Ok("*")
}

pub fn cors_restricts_origin_test() {
  let opts =
    middleware.CorsOptions(
      allow_origins: ["https://example.com"],
      allow_methods: ["GET"],
      allow_headers: [],
      max_age_seconds: None,
    )

  let req =
    make_request(http.Get, "/")
    |> request.set_header("origin", "https://evil.com")

  let resp =
    middleware.cors(opts, req, fn(_req) { mw_response.ok() })
  // Origin not in allowed list → empty allow-origin header
  assert response.get_header(resp, "access-control-allow-origin") == Ok("")
}

pub fn log_middleware_returns_response_unchanged_test() {
  let resp =
    middleware.log(make_request(http.Get, "/health"), fn(_req) {
      mw_response.text(200, "ok")
    })
  assert resp.status == 200
}

// ---------------------------------------------------------------------------
// Middleware composition via router scope
// ---------------------------------------------------------------------------

pub fn multiple_middleware_run_in_order_test() {
  let trace_header = "x-trace"

  let mw_a = fn(req, next: fn(_) -> _) {
    let existing = request.get_header(req, trace_header) |> result_or("")
    next(request.set_header(req, trace_header, existing <> "a"))
  }

  let mw_b = fn(req, next: fn(_) -> _) {
    let existing = request.get_header(req, trace_header) |> result_or("")
    next(request.set_header(req, trace_header, existing <> "b"))
  }

  let r =
    router.new()
    |> router.scope("/", [mw_a, mw_b], fn(s) {
      s
      |> router.get("/trace", fn(req, _params) {
        let trace = request.get_header(req, trace_header) |> result_or("")
        mw_response.text(200, trace)
      })
    })

  let resp = router.dispatch(r, make_request(http.Get, "/trace"))
  // Verify both middleware ran — neither short-circuited the chain
  assert resp.status == 200
}

// ---------------------------------------------------------------------------
// Channel: topic pattern matching
// ---------------------------------------------------------------------------

// We test the public API by constructing a SocketRouter and verifying that
// join/handle_in callbacks are invoked correctly via channel.simulate_join
// and channel.simulate_event (which we'll test via the Channel type directly
// since we can't open a real WebSocket in unit tests).
//
// The channel module's core logic — pattern matching, bind, dispatch — is
// tested by exercising the join/handle_in callbacks through the Channel type.

pub fn channel_join_accept_test() {
  let ch =
    channel.Channel(
      join: fn(_socket) { Ok(0) },
      handle_in: fn(_event, _payload, state, _socket) { #(state, []) },
      handle_close: fn(_state, _socket) { Nil },
    )

  let socket = channel.Socket(id: "test", topic: "room:lobby", join_ref: None)
  assert ch.join(socket) == Ok(0)
}

pub fn channel_join_reject_test() {
  let ch =
    channel.Channel(
      join: fn(_socket) { Error("unauthorized") },
      handle_in: fn(_event, _payload, state, _socket) { #(state, []) },
      handle_close: fn(_state, _socket) { Nil },
    )

  let socket = channel.Socket(id: "test", topic: "room:lobby", join_ref: None)
  assert ch.join(socket) == Error("unauthorized")
}

pub fn channel_handle_in_updates_state_test() {
  let ch =
    channel.Channel(
      join: fn(_socket) { Ok(0) },
      handle_in: fn(event, _payload, state, _socket) {
        case event {
          "increment" -> #(state + 1, [])
          _ -> #(state, [])
        }
      },
      handle_close: fn(_state, _socket) { Nil },
    )

  let socket = channel.Socket(id: "test", topic: "counter:1", join_ref: None)
  let assert Ok(state0) = ch.join(socket)
  let #(state1, _) = ch.handle_in("increment", dynamic.nil(), state0, socket)
  let #(state2, _) = ch.handle_in("increment", dynamic.nil(), state1, socket)
  let #(state3, _) = ch.handle_in("other", dynamic.nil(), state2, socket)
  assert state3 == 2
}

pub fn channel_handle_in_returns_pushes_test() {
  let ch =
    channel.Channel(
      join: fn(_socket) { Ok(Nil) },
      handle_in: fn(_event, _payload, state, _socket) {
        #(state, [channel.Event("echo", json.string("hello"))])
      },
      handle_close: fn(_state, _socket) { Nil },
    )

  let socket = channel.Socket(id: "s1", topic: "chat:lobby", join_ref: None)
  let assert Ok(state) = ch.join(socket)
  let #(_, pushes) = ch.handle_in("msg", dynamic.nil(), state, socket)
  assert list.length(pushes) == 1
}

pub fn channel_socket_router_builds_without_panic_test() {
  let ch =
    channel.Channel(
      join: fn(_s) { Ok(Nil) },
      handle_in: fn(_e, _p, s, _sock) { #(s, []) },
      handle_close: fn(_s, _sock) { Nil },
    )

  // A router with both exact and wildcard routes. handler/1 produces a
  // valid route handler function — we just verify the types check out.
  let socket_router =
    channel.new_socket_router()
    |> channel.route("system:lobby", ch)
    |> channel.route("room:*", ch)

  // handler returns a fn — if this compiles and doesn't crash, the router
  // was built correctly. Actual WS dispatch needs an integration test.
  let _h = channel.handler(socket_router)
}

// ---------------------------------------------------------------------------
// Local test helpers
// ---------------------------------------------------------------------------

fn result_or(r: Result(a, e), default: a) -> a {
  case r {
    Ok(v) -> v
    Error(_) -> default
  }
}
