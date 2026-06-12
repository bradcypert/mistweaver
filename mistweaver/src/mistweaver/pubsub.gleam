import gleam/erlang/process.{type Pid}

/// Start the PubSub process group scope. Call once at application startup,
/// typically from your `main` before `mistweaver.start`. Safe to call
/// multiple times — subsequent calls are no-ops.
pub fn start() -> Nil {
  start_ffi()
}

/// Subscribe the current process to `topic`. Messages arrive as
/// `#("pubsub", topic, message)` — select on them with a custom selector
/// or use `receive_next/2`.
pub fn subscribe(topic: String) -> Nil {
  subscribe_ffi(topic, process.self())
}

/// Unsubscribe the current process from `topic`.
pub fn unsubscribe(topic: String) -> Nil {
  unsubscribe_ffi(topic, process.self())
}

/// Subscribe a specific subject to `topic`. The raw BEAM message
/// `{pubsub, topic, message}` is sent to the subject's owner process.
/// Use `selecting_pubsub/2` to build a typed selector.
pub fn subscribe_pid(topic: String, pid: Pid) -> Nil {
  subscribe_ffi(topic, pid)
}

/// Broadcast `message` to all processes currently subscribed to `topic`.
/// The message is sent as a raw dynamic value; receivers must decode it.
pub fn broadcast(topic: String, message: a) -> Nil {
  broadcast_ffi(topic, message)
}


@external(erlang, "mistweaver_pubsub_ffi", "start")
fn start_ffi() -> Nil

@external(erlang, "mistweaver_pubsub_ffi", "subscribe")
fn subscribe_ffi(topic: String, pid: Pid) -> Nil

@external(erlang, "mistweaver_pubsub_ffi", "unsubscribe")
fn unsubscribe_ffi(topic: String, pid: Pid) -> Nil

@external(erlang, "mistweaver_pubsub_ffi", "broadcast")
fn broadcast_ffi(topic: String, message: a) -> Nil
