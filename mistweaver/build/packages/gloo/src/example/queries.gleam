import gleam/dynamic/decode
import gleam/result
import gloo/error.{type GlooError}
import gloo/query
import gloo/repo.{type Repo}
import gloo/sql
import example/schema

// ── query builder usage (I.query) ─────────────────────────────────────────

pub fn find_user_by_email(
  r: Repo,
  email: String,
) -> Result(schema.User, GlooError) {
  query.from(schema.users())
  |> query.where(query.Eq("email", sql.string(email)))
  |> repo.query_one(r, _)
}

pub fn find_posts_for_user(
  r: Repo,
  user_id: Int,
) -> Result(List(schema.Post), GlooError) {
  query.from(schema.posts())
  |> query.where(query.Eq("user_id", sql.int(user_id)))
  |> query.order_by("inserted_at", query.Desc)
  |> repo.query_all(r, _)
}

pub fn create_user(
  r: Repo,
  email: String,
  name: String,
) -> Result(schema.User, GlooError) {
  query.insert(query.from(schema.users()), schema.users(), [
    #("email", sql.string(email)),
    #("name", sql.string(name)),
  ])
  |> query.returning_columns(["id", "email", "name"])
  |> query.returning(schema.users().decoder)
  |> repo.query_one(r, _)
}

pub fn create_post(
  r: Repo,
  user_id: Int,
  body: String,
) -> Result(schema.Post, GlooError) {
  query.insert(query.from(schema.posts()), schema.posts(), [
    #("user_id", sql.int(user_id)),
    #("body", sql.string(body)),
  ])
  |> query.returning_columns(["id", "user_id", "body"])
  |> query.returning(schema.posts().decoder)
  |> repo.query_one(r, _)
}

pub fn follow_user(
  r: Repo,
  follower_id: Int,
  followee_id: Int,
) -> Result(Int, GlooError) {
  query.insert(query.from(schema.follows()), schema.follows(), [
    #("follower_id", sql.int(follower_id)),
    #("followee_id", sql.int(followee_id)),
  ])
  |> repo.query_execute(r, _)
}

// ── raw sql module usage (I.sql) ───────────────────────────────────────────

pub type FeedPost {
  FeedPost(post_id: Int, author_name: String, body: String)
}

pub fn feed_for_user(
  r: Repo,
  user_id: Int,
  limit: Int,
) -> Result(List(FeedPost), GlooError) {
  let decoder = {
    use post_id <- decode.field(0, decode.int)
    use author_name <- decode.field(1, decode.string)
    use body <- decode.field(2, decode.string)
    decode.success(FeedPost(post_id:, author_name:, body:))
  }
  sql.query(
    "SELECT p.id, u.name, p.body
     FROM posts p
     JOIN users u ON u.id = p.user_id
     WHERE p.user_id IN (
       SELECT followee_id FROM follows WHERE follower_id = $1
     )
     ORDER BY p.inserted_at DESC
     LIMIT $2",
  )
  |> sql.param(sql.int(user_id))
  |> sql.param(sql.int(limit))
  |> sql.returns(decoder)
  |> repo.sql_all(r, _)
}

pub fn delete_user_posts(
  r: Repo,
  user_id: Int,
) -> Result(Int, GlooError) {
  sql.query("DELETE FROM posts WHERE user_id = $1")
  |> sql.param(sql.int(user_id))
  |> repo.sql_execute(r, _)
}

// ── transaction usage (V5, V6) ─────────────────────────────────────────────

pub fn delete_user_and_posts(
  r: Repo,
  user_id: Int,
) -> Result(Nil, GlooError) {
  repo.transaction(r, fn(tx) {
    use _ <- result.try(delete_user_posts(tx, user_id))
    use _ <- result.try(
      query.from(schema.follows())
      |> query.delete
      |> query.where(
        query.Or([
          query.Eq("follower_id", sql.int(user_id)),
          query.Eq("followee_id", sql.int(user_id)),
        ]),
      )
      |> repo.query_execute(tx, _),
    )
    use _ <- result.try(
      repo.execute(tx, "DELETE FROM users WHERE id = $1", [sql.int(user_id)]),
    )
    Ok(Nil)
  })
}
