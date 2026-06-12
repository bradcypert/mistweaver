# Sessions & Auth

## Sessions

Sessions are signed cookies. A secret key is used to sign the cookie value, so tampering is detectable.

```gleam
import mistweaver/session

// Read values
let sess = session.get(c.request, secret)
let user_id = session.fetch(sess, "user_id")  // Option(String)

// Write values — returns a cookie string to set on the response
let cookie =
  session.new()
  |> session.put("user_id", int.to_string(user.id))
  |> session.put("username", user.username)
  |> session.sign(secret)

response.set_header(resp, "set-cookie", "_session=" <> cookie <> "; Path=/; HttpOnly")
```

## auth.load

`auth.load` reads the session on every request and populates `conn.auth` if a valid user is found. Use it at the outermost scope so `conn.auth` is always available.

```gleam
router.scope("/", [auth.load(secret)], fn(r) { ... })
```

If no valid session exists, `conn.auth` is `None`. The request continues normally — `auth.load` never redirects.

## auth.require

`auth.require` calls `auth.load` and then redirects if the result is `None`. Use it on protected scopes.

```gleam
router.scope("/app", [auth.require(secret, to: "/login")], fn(r) {
  // conn.auth is guaranteed Some(_) here
  r |> router.get("/dashboard", dashboard_handler)
})
```

## Flash messages

Flash messages survive exactly one request via a separate signed cookie.

```gleam
import mistweaver/flash

// Set a flash (returns a function that sets the cookie on the response)
let set_flash = flash.set(secret, "Login successful")
resp |> set_flash

// Read and clear a flash
let #(flash_opt, clear_flash) = flash.consume(c.request, secret)
resp |> clear_flash
```

## CSRF protection

CSRF tokens are embedded as hidden form fields and verified on state-changing requests.

```gleam
import mistweaver/csrf

// Generate a token for a form
let token = csrf.token(c.request, secret)

// Verify on POST (returns Error if invalid)
csrf.verify(c.request, secret)
```
