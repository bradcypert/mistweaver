# Telemetry

The `telemetry` module provides structured events that monitoring tools can consume. Events carry a name, numeric measurements, and arbitrary metadata.

## Emitting an event

```gleam
import gleam/dict
import mistweaver/telemetry

telemetry.emit(telemetry.Event(
  name: "myapp.request.stop",
  measurements: dict.from_list([#("duration_ms", 42.0)]),
  metadata: dict.from_list([#("path", dynamic.string("/api/users"))]),
))
```

## Attaching a handler

Handlers are called synchronously when a matching event is emitted. Attach them at startup:

```gleam
telemetry.attach("request-logger", "myapp.request.stop", fn(event) {
  let duration =
    dict.get(event.measurements, "duration_ms")
    |> result.unwrap(0.0)
  logging.log(logging.Info, "request finished in " <> float.to_string(duration) <> "ms")
})
```

## Detaching a handler

```gleam
telemetry.detach("request-logger")
```

## Event naming convention

Use dot-separated names in the form `app.component.action`:

| Name | When |
|---|---|
| `myapp.request.start` | Request received |
| `myapp.request.stop` | Response sent |
| `myapp.db.query` | Database query completed |
| `myapp.job.start` | Background job started |
| `myapp.job.stop` | Background job finished |

## Instrumenting a handler

Wrap a handler to emit start/stop events:

```gleam
fn instrumented(c, params) {
  telemetry.emit(Event(name: "myapp.request.start", ...))
  let start = erlang.system_time(erlang.Millisecond)
  let resp = my_handler(c, params)
  let duration = int.to_float(erlang.system_time(erlang.Millisecond) - start)
  telemetry.emit(Event(
    name: "myapp.request.stop",
    measurements: dict.from_list([#("duration_ms", duration)]),
    metadata: dict.new(),
  ))
  resp
}
```
