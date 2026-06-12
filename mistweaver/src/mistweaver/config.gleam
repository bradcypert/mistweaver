import gleam/option.{type Option}

/// Read an environment variable. Returns None if unset.
pub fn get(key: String) -> Option(String) {
  get_env_ffi(key)
}

/// Read an environment variable. Panics with a clear message if unset.
/// Use at startup to fail fast rather than discover missing config at
/// request time.
///
///   let secret = config.require("APP_SECRET_KEY_BASE")
pub fn require(key: String) -> String {
  case get_env_ffi(key) {
    option.Some(value) -> value
    option.None -> {
      let msg = "Required environment variable is not set: " <> key
      panic as msg
    }
  }
}

/// Read an environment variable, returning `default` if unset.
pub fn get_or(key: String, default: String) -> String {
  get_env_ffi(key) |> option.unwrap(default)
}

@external(erlang, "mistweaver_config_ffi", "get_env")
fn get_env_ffi(key: String) -> Option(String)
