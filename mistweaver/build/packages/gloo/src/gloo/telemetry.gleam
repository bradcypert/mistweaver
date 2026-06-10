////  Event hooks for observability.  Attach a handler with `telemetry.with_handler`
////  and pass the resulting `Telemetry` value to `repo.with_telemetry`.
////
////  Events: `QueryStart`, `QueryEnd`, `QueryError`, `TransactionStart`,
////  `TransactionCommit`, `TransactionRollback`.

import gleam/option.{type Option, None, Some}

pub type Event {
  QueryStart(sql: String, params_count: Int)
  QueryEnd(sql: String, duration_ms: Int, rows: Int)
  QueryError(sql: String, reason: String)
  TransactionStart
  TransactionCommit
  TransactionRollback
}

pub type Handler =
  fn(Event) -> Nil

pub type Telemetry {
  Telemetry(handler: Option(Handler))
}

pub fn disabled() -> Telemetry {
  Telemetry(handler: None)
}

pub fn with_handler(handler: Handler) -> Telemetry {
  Telemetry(handler: Some(handler))
}

pub fn emit(telemetry: Telemetry, event: Event) -> Nil {
  case telemetry.handler {
    None -> Nil
    Some(h) -> h(event)
  }
}
