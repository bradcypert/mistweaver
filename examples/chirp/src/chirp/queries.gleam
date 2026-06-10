import gleam/int
import gloo/error.{type GlooError}
import gloo/repo.{type Repo}
import gloo/sql
import chirp/schema.{type ChirpWithAuthor, type User}

pub fn find_user_by_email(r: Repo, email: String) -> Result(User, GlooError) {
  sql.query(
    "SELECT id, username, email, password_hash FROM users WHERE email = ? LIMIT 1",
  )
  |> sql.param(sql.string(email))
  |> sql.returns(schema.user_decoder())
  |> repo.sql_one(r, _)
}

pub fn find_user_by_id(r: Repo, id: Int) -> Result(User, GlooError) {
  sql.query(
    "SELECT id, username, email, password_hash FROM users WHERE id = ? LIMIT 1",
  )
  |> sql.param(sql.int(id))
  |> sql.returns(schema.user_decoder())
  |> repo.sql_one(r, _)
}

pub fn user_by_username(r: Repo, username: String) -> Result(User, GlooError) {
  sql.query(
    "SELECT id, username, email, password_hash FROM users WHERE username = ? LIMIT 1",
  )
  |> sql.param(sql.string(username))
  |> sql.returns(schema.user_decoder())
  |> repo.sql_one(r, _)
}

pub fn create_user(
  r: Repo,
  username: String,
  email: String,
  password_hash: String,
) -> Result(User, GlooError) {
  sql.query(
    "INSERT INTO users (username, email, password_hash)
     VALUES (?, ?, ?)
     RETURNING id, username, email, password_hash",
  )
  |> sql.param(sql.string(username))
  |> sql.param(sql.string(email))
  |> sql.param(sql.string(password_hash))
  |> sql.returns(schema.user_decoder())
  |> repo.sql_one(r, _)
}

pub fn recent_chirps(
  r: Repo,
  limit: Int,
) -> Result(List(ChirpWithAuthor), GlooError) {
  sql.query(
    "SELECT c.id, c.body, c.inserted_at, u.username
     FROM chirps c
     JOIN users u ON u.id = c.user_id
     ORDER BY c.inserted_at DESC
     LIMIT " <> int.to_string(limit),
  )
  |> sql.returns(schema.chirp_with_author_decoder())
  |> repo.sql_all(r, _)
}

pub fn create_chirp(
  r: Repo,
  user_id: Int,
  body: String,
) -> Result(schema.Chirp, GlooError) {
  sql.query(
    "INSERT INTO chirps (user_id, body)
     VALUES (?, ?)
     RETURNING id, user_id, body, inserted_at",
  )
  |> sql.param(sql.int(user_id))
  |> sql.param(sql.string(body))
  |> sql.returns(schema.chirp_decoder())
  |> repo.sql_one(r, _)
}

pub fn user_chirps(
  r: Repo,
  user_id: Int,
) -> Result(List(ChirpWithAuthor), GlooError) {
  sql.query(
    "SELECT c.id, c.body, c.inserted_at, u.username
     FROM chirps c
     JOIN users u ON u.id = c.user_id
     WHERE c.user_id = ?
     ORDER BY c.inserted_at DESC",
  )
  |> sql.param(sql.int(user_id))
  |> sql.returns(schema.chirp_with_author_decoder())
  |> repo.sql_all(r, _)
}
