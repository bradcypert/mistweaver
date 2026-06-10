import gleam/dynamic/decode

// ---------------------------------------------------------------------------
// Domain types
// ---------------------------------------------------------------------------

pub type User {
  User(
    id: Int,
    username: String,
    email: String,
    password_hash: String,
  )
}

pub type Chirp {
  Chirp(
    id: Int,
    user_id: Int,
    body: String,
    inserted_at: String,
  )
}

pub type ChirpWithAuthor {
  ChirpWithAuthor(
    id: Int,
    body: String,
    inserted_at: String,
    username: String,
  )
}

// ---------------------------------------------------------------------------
// Row decoders (positional by column index)
// ---------------------------------------------------------------------------

pub fn user_decoder() -> decode.Decoder(User) {
  use id <- decode.field(0, decode.int)
  use username <- decode.field(1, decode.string)
  use email <- decode.field(2, decode.string)
  use password_hash <- decode.field(3, decode.string)
  decode.success(User(id:, username:, email:, password_hash:))
}

pub fn chirp_with_author_decoder() -> decode.Decoder(ChirpWithAuthor) {
  use id <- decode.field(0, decode.int)
  use body <- decode.field(1, decode.string)
  use inserted_at <- decode.field(2, decode.string)
  use username <- decode.field(3, decode.string)
  decode.success(ChirpWithAuthor(id:, body:, inserted_at:, username:))
}

pub fn chirp_decoder() -> decode.Decoder(Chirp) {
  use id <- decode.field(0, decode.int)
  use user_id <- decode.field(1, decode.int)
  use body <- decode.field(2, decode.string)
  use inserted_at <- decode.field(3, decode.string)
  decode.success(Chirp(id:, user_id:, body:, inserted_at:))
}
