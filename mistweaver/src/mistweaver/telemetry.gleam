import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}

/// A structured telemetry event. `name` is a dot-separated path following
/// the convention `"app.component.action"` (e.g. `"mistweaver.request.stop"`).
pub type Event {
  Event(
    name: String,
    measurements: Dict(String, Float),
    metadata: Dict(String, Dynamic),
  )
}

/// Emit a telemetry event. Any handlers attached via `attach/2` for this
/// event name will be called synchronously.
pub fn emit(event: Event) -> Nil {
  emit_ffi(event.name, event.measurements, event.metadata)
}

/// Attach a handler function to an event name. The handler is called
/// synchronously whenever `emit/1` is called with a matching name.
///
///   telemetry.attach("my-logger", "mistweaver.request.stop", fn(event) {
///     let duration = dict.get(event.measurements, "duration_ms") |> result.unwrap(0.0)
///     logging.log(logging.Info, "request took " <> float.to_string(duration) <> "ms")
///   })
pub fn attach(id: String, name: String, handler: fn(Event) -> Nil) -> Nil {
  let wrapper = fn(n: String, m: Dict(String, Float), meta: Dict(String, Dynamic)) {
    handler(Event(name: n, measurements: m, metadata: meta))
  }
  attach_ffi(id, name, wrapper)
}

/// Detach a handler previously registered with `attach/3`.
pub fn detach(id: String) -> Nil {
  detach_ffi(id)
}

@external(erlang, "mistweaver_telemetry_ffi", "emit")
fn emit_ffi(
  name: String,
  measurements: Dict(String, Float),
  metadata: Dict(String, Dynamic),
) -> Nil

@external(erlang, "mistweaver_telemetry_ffi", "attach")
fn attach_ffi(
  id: String,
  name: String,
  handler: fn(String, Dict(String, Float), Dict(String, Dynamic)) -> Nil,
) -> Nil

@external(erlang, "mistweaver_telemetry_ffi", "detach")
fn detach_ffi(id: String) -> Nil
