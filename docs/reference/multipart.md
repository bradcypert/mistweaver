# multipart

Parses `multipart/form-data` request bodies into typed parts.

## Types

```gleam
pub type Part {
  Field(name: String, value: String)
  Upload(name: String, filename: String, content_type: String, data: BitArray)
}
```

## Functions

### `parse`
```gleam
pub fn parse(req: Request(BitArray)) -> Result(List(Part), String)
```
Parse a multipart request body. Returns `Error` if the `Content-Type` header is missing, not `multipart/form-data`, has no boundary, or the body is not valid UTF-8.

Requires the body to already be buffered — use `middleware.body_limit` upstream.

---

### `get_field`
```gleam
pub fn get_field(parts: List(Part), name: String) -> Option(String)
```
Find the first `Field` part with the given name. Returns `None` if not found.

---

### `uploads`
```gleam
pub fn uploads(parts: List(Part)) -> List(Part)
```
Filter the parts list to only `Upload` variants.
