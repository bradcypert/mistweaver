# File Uploads

Use `multipart.parse` to handle `multipart/form-data` requests.

## Parsing the body

First, read the full body with `middleware.body_limit`, then parse:

```gleam
import mistweaver/multipart

// In your handler (body already read by body_limit middleware):
case multipart.parse(c.request) {
  Error(e)    -> mw_response.bad_request(e)
  Ok(parts)  -> handle_parts(parts)
}
```

## Accessing fields

```gleam
let name = multipart.get_field(parts, "name") |> option.unwrap("")
```

## Accessing uploads

```gleam
let files = multipart.uploads(parts)

list.each(files, fn(part) {
  let assert Upload(name, filename, content_type, data) = part
  // data is BitArray — write to disk, store in S3, etc.
  save_upload(filename, data)
})
```

## HTML form

```html
<form method="POST" action="/upload" enctype="multipart/form-data">
  <input type="text" name="title" />
  <input type="file" name="attachment" />
  <button type="submit">Upload</button>
</form>
```

## Body size limit

Always pair multipart parsing with `middleware.body_limit` to prevent large uploads from exhausting memory:

```gleam
router.scope("/", [middleware.body_limit(10 * 1024 * 1024)], fn(r) {
  r |> router.post("/upload", upload_handler)
})
```
