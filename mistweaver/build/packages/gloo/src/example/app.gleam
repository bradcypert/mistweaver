import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gloo/error
import gloo/runner
import gloo/validate
import example/migrations
import example/queries
import gloo/adapter/postgres

pub fn main() {
  let assert Ok(r) =
    postgres.default_config()
    |> postgres.database("gloo_example")
    |> postgres.password(Some("postgres"))
    |> postgres.start()

  io.println("=== gloo example app ===\n")

  // ── migrations ─────────────────────────────────────────────────────────────
  io.println("Running migrations...")
  let migs = migrations.all()
  let assert Ok(applied) = runner.run(r, migs, runner.Up, None)
  case applied {
    0 -> io.println("Already up to date.")
    n -> io.println("Applied " <> int.to_string(n) <> " migration(s).")
  }
  io.println("")

  // ── validation ─────────────────────────────────────────────────────────────
  io.println("Validating inputs...")
  let bad = validate.struct([
    validate.field("email", "not-an-email", [
      validate.format("^[^@]+@[^@]+\\.[^@]+$"),
    ]),
    validate.field("name", "", [validate.max_length(100)]),
  ])
  case bad {
    Ok(_) -> io.println("unexpected ok")
    Error(errs) ->
      list.each(errs, fn(e) {
        let validate.FieldError(field:, message:) = e
        io.println("  validation error — " <> field <> ": " <> message)
      })
  }
  io.println("")

  // ── seed users ─────────────────────────────────────────────────────────────
  io.println("Creating users...")
  let assert Ok(alice) = queries.create_user(r, "alice@example.com", "Alice")
  let assert Ok(bob) = queries.create_user(r, "bob@example.com", "Bob")
  let assert Ok(carol) = queries.create_user(r, "carol@example.com", "Carol")
  io.println("  created: " <> alice.name <> " (id=" <> int.to_string(alice.id) <> ")")
  io.println("  created: " <> bob.name <> " (id=" <> int.to_string(bob.id) <> ")")
  io.println("  created: " <> carol.name <> " (id=" <> int.to_string(carol.id) <> ")")
  io.println("")

  // ── constraint violation ───────────────────────────────────────────────────
  io.println("Testing constraint violation (duplicate email)...")
  case queries.create_user(r, "alice@example.com", "Alice2") {
    Ok(_) -> io.println("  unexpected ok")
    Error(error.ConstraintError(name:)) ->
      io.println("  caught ConstraintError: " <> name)
    Error(e) -> io.println("  unexpected error: " <> error.to_string(e))
  }
  io.println("")

  // ── follows ────────────────────────────────────────────────────────────────
  io.println("Creating follows...")
  let assert Ok(_) = queries.follow_user(r, bob.id, alice.id)
  let assert Ok(_) = queries.follow_user(r, carol.id, alice.id)
  io.println("  bob -> alice, carol -> alice")
  io.println("")

  // ── posts ──────────────────────────────────────────────────────────────────
  io.println("Creating posts...")
  let assert Ok(p1) = queries.create_post(r, alice.id, "Hello from Alice!")
  let assert Ok(_) = queries.create_post(r, alice.id, "Second post from Alice.")
  io.println("  alice posted: \"" <> p1.body <> "\"")
  io.println("")

  // ── feed query (raw SQL join) ───────────────────────────────────────────────
  io.println("Feed for Bob (follows Alice)...")
  let assert Ok(feed) = queries.feed_for_user(r, bob.id, 10)
  list.each(feed, fn(fp) {
    io.println(
      "  [" <> int.to_string(fp.post_id) <> "] " <> fp.author_name <> ": " <> fp.body,
    )
  })
  io.println("")

  // ── query builder: find by email ───────────────────────────────────────────
  io.println("Find user by email...")
  let assert Ok(found) = queries.find_user_by_email(r, "carol@example.com")
  io.println("  found: " <> found.name <> " <" <> found.email <> ">")
  io.println("")

  // ── transaction: delete user + posts atomically ────────────────────────────
  io.println("Deleting Alice and her posts in a transaction...")
  let assert Ok(Nil) = queries.delete_user_and_posts(r, alice.id)
  io.println("  done.")
  io.println("")

  // ── verify deletion ────────────────────────────────────────────────────────
  io.println("Verifying Alice is gone...")
  case queries.find_user_by_email(r, "alice@example.com") {
    Error(error.NoResultError) -> io.println("  confirmed: no result.")
    Ok(u) -> io.println("  unexpected: still found " <> u.name)
    Error(e) -> io.println("  unexpected error: " <> error.to_string(e))
  }
  io.println("")

  // ── cleanup: roll back migrations so re-runs start fresh ──────────────────
  io.println("Rolling back all migrations...")
  let assert Ok(rolled) =
    runner.run(r, migs, runner.Down, Some(list.length(migs)))
  io.println("Rolled back " <> int.to_string(rolled) <> " migration(s).")
  io.println("\n=== all done ===")
}
