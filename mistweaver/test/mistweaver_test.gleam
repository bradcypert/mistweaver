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
import mistweaver/changeset
import mistweaver/config
import mistweaver/conn.{type Conn, Conn}
import mistweaver/middleware
import mistweaver/multipart
import mistweaver/request as mw_request
import mistweaver/rescue
import mistweaver/response as mw_response
import mistweaver/router
import mistweaver/test_conn

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

fn make_conn(method: http.Method, path: String) -> Conn(Nil) {
  conn.new(make_request(method, path))
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
    |> router.get("/hello", fn(_c, _params) { ok_text("hello") })

  let resp = router.dispatch(r, make_request(http.Get, "/hello"))
  assert resp.status == 200
}

pub fn dispatches_post_test() {
  let r =
    router.new()
    |> router.post("/items", fn(_c, _params) { mw_response.text(201, "created") })

  let resp = router.dispatch(r, make_request(http.Post, "/items"))
  assert resp.status == 201
}

pub fn method_mismatch_returns_404_test() {
  let r =
    router.new()
    |> router.get("/hello", fn(_c, _params) { ok_text("hello") })

  let resp = router.dispatch(r, make_request(http.Post, "/hello"))
  assert resp.status == 404
}

pub fn unknown_path_returns_404_test() {
  let r =
    router.new()
    |> router.get("/hello", fn(_c, _params) { ok_text("hello") })

  let resp = router.dispatch(r, make_request(http.Get, "/goodbye"))
  assert resp.status == 404
}

// ---------------------------------------------------------------------------
// Router: path parameters
// ---------------------------------------------------------------------------

pub fn captures_single_path_param_test() {
  let r =
    router.new()
    |> router.get("/users/:id", fn(_c, params) {
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
    |> router.get("/orgs/:org/repos/:repo", fn(_c, params) {
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
    |> router.get("/users/:id", fn(_c, _params) { ok_text("ok") })

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
      s |> router.get("/users", fn(_c, _params) { ok_text("users") })
    })

  let ok = router.dispatch(r, make_request(http.Get, "/api/users"))
  assert ok.status == 200

  let nf = router.dispatch(r, make_request(http.Get, "/users"))
  assert nf.status == 404
}

pub fn scope_middleware_runs_before_handler_test() {
  let marker = "x-scope-ran"

  let scope_mw = fn(c: Conn(Nil), next: fn(Conn(Nil)) -> _) {
    next(Conn(..c, request: request.set_header(c.request, marker, "true")))
  }

  let r =
    router.new()
    |> router.scope("/api", [scope_mw], fn(s) {
      s
      |> router.get("/ping", fn(c, _params) {
        case request.get_header(c.request, marker) {
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
        |> router.get("/users", fn(_c, _params) { ok_text("admin users") })
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
    middleware.request_id(make_conn(http.Get, "/"), fn(_c) {
      mw_response.ok()
    })
  assert response.get_header(resp, "x-request-id") != Error(Nil)
}

pub fn request_id_propagates_existing_test() {
  let c =
    make_conn(http.Get, "/")
    |> fn(c) { Conn(..c, request: request.set_header(c.request, "x-request-id", "my-custom-id")) }

  let resp = middleware.request_id(c, fn(_c) { mw_response.ok() })
  assert response.get_header(resp, "x-request-id") == Ok("my-custom-id")
}

pub fn request_id_echoes_id_in_response_test() {
  let c =
    make_conn(http.Get, "/")
    |> fn(c) { Conn(..c, request: request.set_header(c.request, "x-request-id", "echo-me")) }

  let resp = middleware.request_id(c, fn(_c) { mw_response.ok() })
  assert response.get_header(resp, "x-request-id") == Ok("echo-me")
}

pub fn cors_adds_headers_test() {
  let opts = middleware.cors_allow_all()
  let resp =
    middleware.cors(opts, make_conn(http.Get, "/"), fn(_c) {
      mw_response.ok()
    })
  assert response.get_header(resp, "access-control-allow-origin") == Ok("*")
  assert response.get_header(resp, "access-control-allow-methods") != Error(Nil)
}

pub fn cors_handles_preflight_test() {
  let opts = middleware.cors_allow_all()
  let resp =
    middleware.cors(opts, make_conn(http.Options, "/api/users"), fn(_c) {
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

  let c =
    make_conn(http.Get, "/")
    |> fn(c) { Conn(..c, request: request.set_header(c.request, "origin", "https://evil.com")) }

  let resp =
    middleware.cors(opts, c, fn(_c) { mw_response.ok() })
  assert response.get_header(resp, "access-control-allow-origin") == Ok("")
}

pub fn log_middleware_returns_response_unchanged_test() {
  let resp =
    middleware.log(make_conn(http.Get, "/health"), fn(_c) {
      mw_response.text(200, "ok")
    })
  assert resp.status == 200
}

// ---------------------------------------------------------------------------
// Middleware composition via router scope
// ---------------------------------------------------------------------------

pub fn multiple_middleware_run_in_order_test() {
  let trace_header = "x-trace"

  let mw_a = fn(c: Conn(Nil), next: fn(Conn(Nil)) -> _) {
    let existing = request.get_header(c.request, trace_header) |> result_or("")
    next(Conn(..c, request: request.set_header(c.request, trace_header, existing <> "a")))
  }

  let mw_b = fn(c: Conn(Nil), next: fn(Conn(Nil)) -> _) {
    let existing = request.get_header(c.request, trace_header) |> result_or("")
    next(Conn(..c, request: request.set_header(c.request, trace_header, existing <> "b")))
  }

  let r =
    router.new()
    |> router.scope("/", [mw_a, mw_b], fn(s) {
      s
      |> router.get("/trace", fn(c, _params) {
        let trace = request.get_header(c.request, trace_header) |> result_or("")
        mw_response.text(200, trace)
      })
    })

  let resp = router.dispatch(r, make_request(http.Get, "/trace"))
  assert resp.status == 200
}

// ---------------------------------------------------------------------------
// Channel: topic pattern matching
// ---------------------------------------------------------------------------

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

  let socket_router =
    channel.new_socket_router()
    |> channel.route("system:lobby", ch)
    |> channel.route("room:*", ch)

  let _h = channel.handler(socket_router)
}

// ---------------------------------------------------------------------------
// Changeset
// ---------------------------------------------------------------------------

pub fn changeset_valid_when_all_required_present_test() {
  let cs =
    [#("name", "Alice"), #("email", "alice@example.com")]
    |> changeset.cast(required: ["name", "email"])
  assert changeset.valid(cs) == True
}

pub fn changeset_invalid_when_required_missing_test() {
  let cs =
    [#("name", "Alice")]
    |> changeset.cast(required: ["name", "email"])
  assert changeset.valid(cs) == False
  assert changeset.errors_for(cs, "email") == ["is required"]
}

pub fn changeset_invalid_when_required_blank_test() {
  let cs =
    [#("name", "  ")]
    |> changeset.cast(required: ["name"])
  assert changeset.valid(cs) == False
  assert changeset.errors_for(cs, "name") == ["is required"]
}

pub fn changeset_get_returns_value_test() {
  let cs =
    [#("role", "admin")]
    |> changeset.cast(required: [])
  assert changeset.get(cs, "role") == Some("admin")
  assert changeset.get(cs, "missing") == None
}

pub fn changeset_get_or_returns_default_test() {
  let cs = [] |> changeset.cast(required: [])
  assert changeset.get_or(cs, "lang", "en") == "en"
}

pub fn changeset_validate_length_min_test() {
  let cs =
    [#("password", "abc")]
    |> changeset.cast(required: ["password"])
    |> changeset.validate_length("password", min: Some(8), max: None)
  assert changeset.valid(cs) == False
  assert list.length(changeset.errors_for(cs, "password")) == 1
}

pub fn changeset_validate_length_max_test() {
  let cs =
    [#("bio", "way too long string that exceeds ten characters")]
    |> changeset.cast(required: ["bio"])
    |> changeset.validate_length("bio", min: None, max: Some(10))
  assert changeset.valid(cs) == False
}

pub fn changeset_validate_length_passes_within_bounds_test() {
  let cs =
    [#("username", "alice")]
    |> changeset.cast(required: ["username"])
    |> changeset.validate_length("username", min: Some(3), max: Some(20))
  assert changeset.valid(cs) == True
}

pub fn changeset_validate_format_fails_test() {
  let cs =
    [#("email", "not-an-email")]
    |> changeset.cast(required: ["email"])
    |> changeset.validate_format(
      "email",
      with: fn(v) { v |> fn(s) { s == "x" || s != "x" && s != "not-an-email" } },
      message: "is invalid",
    )
  assert list.length(changeset.errors_for(cs, "email")) == 1
}

pub fn changeset_validate_inclusion_fails_test() {
  let cs =
    [#("role", "superadmin")]
    |> changeset.cast(required: ["role"])
    |> changeset.validate_inclusion("role", in: ["admin", "user"])
  assert changeset.valid(cs) == False
  assert changeset.errors_for(cs, "role") == ["is not a valid value"]
}

pub fn changeset_validate_inclusion_passes_test() {
  let cs =
    [#("role", "admin")]
    |> changeset.cast(required: ["role"])
    |> changeset.validate_inclusion("role", in: ["admin", "user"])
  assert changeset.valid(cs) == True
}

pub fn changeset_multiple_errors_accumulate_test() {
  let cs =
    [#("password", "ab")]
    |> changeset.cast(required: ["password", "email"])
    |> changeset.validate_length("password", min: Some(8), max: None)
  assert changeset.valid(cs) == False
  assert list.length(changeset.errors_for(cs, "email")) == 1
  assert list.length(changeset.errors_for(cs, "password")) == 1
}

// ---------------------------------------------------------------------------
// Multipart
// ---------------------------------------------------------------------------

pub fn multipart_parses_form_field_test() {
  let boundary = "testboundary"
  let body =
    "--testboundary\r\nContent-Disposition: form-data; name=\"username\"\r\n\r\nalice\r\n--testboundary--"
  let req =
    request.Request(
      method: http.Post,
      headers: [
        #(
          "content-type",
          "multipart/form-data; boundary=" <> boundary,
        ),
      ],
      body: <<body:utf8>>,
      scheme: http.Http,
      host: "localhost",
      port: None,
      path: "/upload",
      query: None,
    )

  let assert Ok(parts) = multipart.parse(req)
  assert multipart.get_field(parts, "username") == Some("alice")
}

pub fn multipart_parses_multiple_fields_test() {
  let body =
    "--b\r\nContent-Disposition: form-data; name=\"a\"\r\n\r\n1\r\n--b\r\nContent-Disposition: form-data; name=\"b\"\r\n\r\n2\r\n--b--"
  let req =
    request.Request(
      method: http.Post,
      headers: [#("content-type", "multipart/form-data; boundary=b")],
      body: <<body:utf8>>,
      scheme: http.Http,
      host: "localhost",
      port: None,
      path: "/",
      query: None,
    )

  let assert Ok(parts) = multipart.parse(req)
  assert multipart.get_field(parts, "a") == Some("1")
  assert multipart.get_field(parts, "b") == Some("2")
}

pub fn multipart_missing_content_type_returns_error_test() {
  let req =
    request.Request(
      method: http.Post,
      headers: [],
      body: <<"body":utf8>>,
      scheme: http.Http,
      host: "localhost",
      port: None,
      path: "/",
      query: None,
    )
  assert multipart.parse(req) == Error("missing Content-Type header")
}

pub fn multipart_wrong_content_type_returns_error_test() {
  let req =
    request.Request(
      method: http.Post,
      headers: [#("content-type", "application/json")],
      body: <<"{}":utf8>>,
      scheme: http.Http,
      host: "localhost",
      port: None,
      path: "/",
      query: None,
    )
  assert multipart.parse(req) == Error("Content-Type is not multipart/form-data")
}

pub fn multipart_get_field_missing_returns_none_test() {
  let assert Ok(parts) = multipart.parse(
    request.Request(
      method: http.Post,
      headers: [#("content-type", "multipart/form-data; boundary=b")],
      body: <<"--b\r\nContent-Disposition: form-data; name=\"x\"\r\n\r\nhello\r\n--b--":utf8>>,
      scheme: http.Http,
      host: "localhost",
      port: None,
      path: "/",
      query: None,
    ),
  )
  assert multipart.get_field(parts, "missing") == None
}

pub fn multipart_uploads_filters_non_file_parts_test() {
  let body =
    "--b\r\nContent-Disposition: form-data; name=\"title\"\r\n\r\nhello\r\n--b\r\nContent-Disposition: form-data; name=\"file\"; filename=\"test.txt\"\r\nContent-Type: text/plain\r\n\r\nfile contents\r\n--b--"
  let req =
    request.Request(
      method: http.Post,
      headers: [#("content-type", "multipart/form-data; boundary=b")],
      body: <<body:utf8>>,
      scheme: http.Http,
      host: "localhost",
      port: None,
      path: "/",
      query: None,
    )
  let assert Ok(parts) = multipart.parse(req)
  let uploads = multipart.uploads(parts)
  assert list.length(uploads) == 1
}

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

pub fn config_get_returns_none_for_unset_test() {
  assert config.get("MW_TEST_DEFINITELY_NOT_SET_XYZ123") == None
}

pub fn config_get_or_returns_default_for_unset_test() {
  assert config.get_or("MW_TEST_DEFINITELY_NOT_SET_XYZ123", "fallback")
    == "fallback"
}

// ---------------------------------------------------------------------------
// Rescue
// ---------------------------------------------------------------------------

pub fn rescue_passes_through_normal_response_test() {
  let c = test_conn.get("/")
  let resp = rescue.middleware(c, fn(_c) { mw_response.text(200, "ok") })
  assert resp.status == 200
}

pub fn rescue_catches_panic_and_returns_500_test() {
  let c = test_conn.get("/")
  let resp =
    rescue.middleware(c, fn(_c) { panic as "something went wrong" })
  assert resp.status == 500
}

// ---------------------------------------------------------------------------
// test_conn helpers
// ---------------------------------------------------------------------------

pub fn test_conn_get_builds_conn_test() {
  let c = test_conn.get("/users")
  assert c.request.method == http.Get
  assert c.request.path == "/users"
}

pub fn test_conn_post_builds_conn_test() {
  let c = test_conn.post("/users")
  assert c.request.method == http.Post
}

pub fn test_conn_with_header_test() {
  let c = test_conn.get("/") |> test_conn.with_header("x-custom", "value")
  assert request.get_header(c.request, "x-custom") == Ok("value")
}

pub fn test_conn_with_auth_sets_auth_test() {
  let c = test_conn.get("/") |> test_conn.with_auth(42, "alice")
  assert c.auth == Some(conn.AuthUser(id: 42, username: "alice"))
}

pub fn test_conn_assert_status_passes_test() {
  let resp = mw_response.html(200, "ok")
  let _ = test_conn.assert_status(resp, 200)
}

pub fn test_conn_assert_redirect_passes_test() {
  let resp = mw_response.redirect(302, to: "/login")
  let _ = test_conn.assert_redirect(resp, to: "/login")
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
