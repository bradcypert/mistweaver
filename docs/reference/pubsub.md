# pubsub

Process-group-based PubSub built on Erlang's `pg` module. Dead processes are cleaned up automatically.

## Functions

### `start`
```gleam
pub fn start() -> Nil
```
Start the PubSub scope. Call once at boot before `mistweaver.start`. Safe to call multiple times.

---

### `subscribe`
```gleam
pub fn subscribe(topic: String) -> Nil
```
Subscribe the current process to `topic`. Messages arrive as the raw Erlang term `{pubsub, topic, message}`.

---

### `unsubscribe`
```gleam
pub fn unsubscribe(topic: String) -> Nil
```
Unsubscribe the current process from `topic`.

---

### `subscribe_pid`
```gleam
pub fn subscribe_pid(topic: String, pid: Pid) -> Nil
```
Subscribe a specific process by `Pid`. Useful for subscribing on behalf of another actor.

---

### `broadcast`
```gleam
pub fn broadcast(topic: String, message: a) -> Nil
```
Send `message` to every process currently subscribed to `topic`.
