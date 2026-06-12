# config

Environment variable access with clear failure modes.

## Functions

### `get`
```gleam
pub fn get(key: String) -> Option(String)
```
Read an environment variable. Returns `None` if not set.

---

### `get_or`
```gleam
pub fn get_or(key: String, default: String) -> String
```
Read an environment variable, returning `default` if unset.

---

### `require`
```gleam
pub fn require(key: String) -> String
```
Read an environment variable. Panics at startup with a descriptive message if the variable is not set. Use this for required configuration — failing fast at boot is better than a confusing error at request time.
