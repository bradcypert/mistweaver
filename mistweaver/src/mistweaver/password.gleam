import gleam/bit_array
import gleam/crypto
import gleam/string

/// Hash a password using PBKDF2-SHA256 with 100,000 iterations.
/// Returns a self-describing string: "pbkdf2$<hex_salt>$<hex_hash>"
pub fn hash(password: String) -> String {
  let salt = crypto.strong_random_bytes(16)
  let hash = pbkdf2_hash(<<password:utf8>>, salt, 100_000, 32)
  "pbkdf2$"
  <> bit_array.base16_encode(salt)
  <> "$"
  <> bit_array.base16_encode(hash)
}

/// Verify a plaintext password against a value produced by `hash/1`.
pub fn verify(password: String, stored: String) -> Bool {
  case string.split(stored, "$") {
    ["pbkdf2", salt_hex, stored_hash_hex] ->
      case bit_array.base16_decode(salt_hex) {
        Ok(salt) -> {
          let computed = pbkdf2_hash(<<password:utf8>>, salt, 100_000, 32)
          let computed_hex = bit_array.base16_encode(computed)
          crypto.secure_compare(<<computed_hex:utf8>>, <<stored_hash_hex:utf8>>)
        }
        Error(_) -> False
      }
    _ -> False
  }
}

@external(erlang, "mistweaver_password_ffi", "pbkdf2_hash")
fn pbkdf2_hash(
  password: BitArray,
  salt: BitArray,
  iterations: Int,
  key_length: Int,
) -> BitArray
