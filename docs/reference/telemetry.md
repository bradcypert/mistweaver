# telemetry

Structured events for monitoring and instrumentation.

## Types

```gleam
pub type Event {
  Event(
    name: String,
    measurements: Dict(String, Float),
    metadata: Dict(String, Dynamic),
  )
}
```

`name` follows the `"app.component.action"` convention (e.g. `"myapp.request.stop"`).

## Functions

### `emit`
```gleam
pub fn emit(event: Event) -> Nil
```
Emit an event. All handlers attached for this event name are called synchronously.

---

### `attach`
```gleam
pub fn attach(id: String, name: String, handler: fn(Event) -> Nil) -> Nil
```
Register a handler for events with the given name. `id` identifies the handler so it can be detached later. Attaching the same `id` again replaces the previous handler.

---

### `detach`
```gleam
pub fn detach(id: String) -> Nil
```
Remove the handler registered under `id`.
