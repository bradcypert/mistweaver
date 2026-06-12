# session

Signed cookie-based sessions. The session is serialized, signed with HMAC-SHA256, and stored in the `_mw_session` cookie.

## Types

```gleam
pub type Session = Dict(String, String)
```

## Functions

### `get`
```gleam
pub fn get(req: Request(body), secret: String) -> Session
```
Read and verify the session from the request cookie. Returns an empty session if the cookie is absent or the signature is invalid.

---

### `put`
```gleam
pub fn put(resp: Response(ResponseData), session: Session, secret: String) -> Response(ResponseData)
```
Sign the session and set it as a cookie on the response.

---

### `delete`
```gleam
pub fn delete(resp: Response(ResponseData)) -> Response(ResponseData)
```
Expire the session cookie (sets `Max-Age=0`).

---

### `empty`
```gleam
pub fn empty() -> Session
```
Return a new empty session.

---

### `set`
```gleam
pub fn set(session: Session, key: String, value: String) -> Session
```
Add or update a key in the session.

---

### `fetch`
```gleam
pub fn fetch(session: Session, key: String) -> Option(String)
```
Read a value from the session. Returns `None` if the key is absent.

---

### `delete_key`
```gleam
pub fn delete_key(session: Session, key: String) -> Session
```
Remove a key from the session.

---

### `sign`
```gleam
pub fn sign(session: Session, secret: String) -> String
```
Encode and sign the session, returning the raw cookie value. Primarily used by `test_conn.with_session`.
