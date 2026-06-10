import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/otp/actor
import gleam/otp/static_supervisor.{type Supervisor}
import mist.{type Connection, type ResponseData}
import mistweaver/router

pub type MistWeaverError {
  StartError(actor.StartError)
}

pub opaque type Config {
  Config(
    port: Int,
    interface: String,
    ipv6: Bool,
  )
}

/// Create a default server configuration on port 4000.
pub fn new_config() -> Config {
  Config(port: 4000, interface: "localhost", ipv6: False)
}

/// Set the port the server listens on.
pub fn port(config: Config, port: Int) -> Config {
  Config(..config, port: port)
}

/// Set the interface to bind to (e.g. "0.0.0.0" for all interfaces).
pub fn bind(config: Config, interface: String) -> Config {
  Config(..config, interface: interface)
}

/// Enable IPv6 support.
pub fn with_ipv6(config: Config) -> Config {
  Config(..config, ipv6: True)
}

/// Start the server with a compiled Router. The router's `dispatch` function
/// becomes the Mist handler. Blocks until the process receives a shutdown signal.
pub fn start(
  config: Config,
  r: router.Router(Connection),
) -> Result(actor.Started(Supervisor), MistWeaverError) {
  start_mist(config, router.dispatch(r, _))
}

/// Start the server with a raw handler function instead of a Router. Useful
/// for apps that compose middleware manually before handing off to a router.
pub fn start_with_handler(
  config: Config,
  handler: fn(Request(Connection)) -> Response(ResponseData),
) -> Result(actor.Started(Supervisor), MistWeaverError) {
  start_mist(config, handler)
}

/// Block the calling process indefinitely, keeping the server alive.
/// Call after `start/2` to keep a standalone Erlang node running.
pub fn wait_forever() -> Nil {
  process.sleep_forever()
}

fn start_mist(
  config: Config,
  handler: fn(Request(Connection)) -> Response(ResponseData),
) -> Result(actor.Started(Supervisor), MistWeaverError) {
  mist.new(handler)
  |> mist.port(config.port)
  |> mist.bind(config.interface)
  |> fn(builder) {
    case config.ipv6 {
      True -> mist.with_ipv6(builder)
      False -> builder
    }
  }
  |> mist.start()
  |> fn(result) {
    case result {
      Ok(started) -> Ok(started)
      Error(err) -> Error(StartError(err))
    }
  }
}
