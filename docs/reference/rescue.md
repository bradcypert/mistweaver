# rescue

Error boundary middleware that turns unhandled crashes into `500` responses.

## Functions

### `middleware`
```gleam
pub fn middleware(
  c: Conn(body),
  next: fn(Conn(body)) -> Response(ResponseData),
) -> Response(ResponseData)
```
Wraps `next(c)` in a try/catch. If the handler raises, panics, or hits a failed `let assert`, the error is logged via Erlang's `logger` and a `500 Internal Server Error` HTML response is returned.

Place this as the **outermost** middleware in your top-level scope so it covers the entire request pipeline:

```gleam
router.scope("/", [rescue.middleware, auth.load(secret)], fn(r) { ... })
```
