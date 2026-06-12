# PubSub

Mistweaver's PubSub is built on Erlang's `pg` (process groups) module. Processes subscribe to named topics and receive messages when any process broadcasts to that topic.

## Starting PubSub

Call `pubsub.start()` once at application boot, before `mistweaver.start`:

```gleam
pub fn main() {
  pubsub.start()
  let assert Ok(_) = mistweaver.new_config() |> mistweaver.start(router)
  process.sleep_forever()
}
```

## Subscribe and broadcast

```gleam
import mistweaver/pubsub

// Subscribe the current process
pubsub.subscribe("room:lobby")

// Broadcast to all subscribers
pubsub.broadcast("room:lobby", MyMessage("hello"))
```

Messages arrive as raw Erlang messages `{pubsub, topic, message}`. Use `process.new_selector()` and `process.selecting_anything` to receive them in a typed actor.

## Unsubscribe

```gleam
pubsub.unsubscribe("room:lobby")
```

Dead processes are cleaned up automatically by the `pg` module — no manual cleanup needed when a process crashes.

## LiveView integration

Subscribe a LiveView process in `init` and dispatch incoming messages as component updates:

```gleam
pub fn init(user_id: Int) -> #(Model, lustre.Effect(Msg)) {
  let effect = lustre.effect(fn(_dispatch) {
    pubsub.subscribe("user:" <> int.to_string(user_id))
  })
  #(Model(...), effect)
}
```
