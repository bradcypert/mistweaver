# Testing

The `test_conn` module provides request builders and response assertions so you can test handlers without running an HTTP server.

## Building a request

```gleam
import mistweaver/test_conn

// GET /users
let conn = test_conn.get("/users")

// POST /users with a JSON body
let conn =
  test_conn.post("/users")
  |> test_conn.with_json("{\"name\": \"Alice\"}")

// POST with form params
let conn =
  test_conn.post("/login")
  |> test_conn.with_form([#("email", "alice@example.com"), #("password", "secret")])
```

## Authenticated requests

```gleam
// Inject an AuthUser directly (no session needed)
let conn =
  test_conn.get("/dashboard")
  |> test_conn.with_auth(42, "alice")

// Or inject via session cookie (round-trips through session.sign)
let conn =
  test_conn.get("/dashboard")
  |> test_conn.with_session([#("user_id", "42"), #("username", "alice")], secret)
```

## Calling a handler

```gleam
let resp = my_handler(conn, [])
```

## Assertions

```gleam
resp
|> test_conn.assert_status(200)
|> test_conn.assert_header("content-type", "text/html; charset=utf-8")

// For redirects
resp |> test_conn.assert_redirect(to: "/login")

// Read the body
let body = test_conn.response_body(resp)
let assert True = string.contains(body, "Welcome")
```

## Full example

```gleam
import gleeunit/should
import mistweaver/test_conn
import myapp/controllers/users

pub fn create_user_test() {
  let resp =
    test_conn.post("/users")
    |> test_conn.with_form([
      #("username", "alice"),
      #("email", "alice@example.com"),
    ])
    |> users.create(repo, secret)

  resp |> test_conn.assert_status(302)
  resp |> test_conn.assert_redirect(to: "/dashboard")
}
```
