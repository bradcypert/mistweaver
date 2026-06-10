import gleam/dynamic/decode
import gloo/schema.{type Table, Table}

// ── User ───────────────────────────────────────────────────────────────────

pub type User {
  User(id: Int, email: String, name: String)
}

pub fn users() -> Table(User) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use email <- decode.field(1, decode.string)
    use name <- decode.field(2, decode.string)
    decode.success(User(id:, email:, name:))
  }
  Table(name: "users", primary_key: "id", decoder:)
}

// ── Post ───────────────────────────────────────────────────────────────────

pub type Post {
  Post(id: Int, user_id: Int, body: String)
}

pub fn posts() -> Table(Post) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use user_id <- decode.field(1, decode.int)
    use body <- decode.field(2, decode.string)
    decode.success(Post(id:, user_id:, body:))
  }
  Table(name: "posts", primary_key: "id", decoder:)
}

// ── Follow ─────────────────────────────────────────────────────────────────

pub type Follow {
  Follow(follower_id: Int, followee_id: Int)
}

pub fn follows() -> Table(Follow) {
  let decoder = {
    use follower_id <- decode.field(0, decode.int)
    use followee_id <- decode.field(1, decode.int)
    decode.success(Follow(follower_id:, followee_id:))
  }
  Table(name: "follows", primary_key: "follower_id", decoder:)
}
