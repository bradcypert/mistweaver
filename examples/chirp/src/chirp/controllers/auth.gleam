import gleam/http.{Get, Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/list
import gleam/option
import gleam/string
import gloo/repo.{type Repo}
import lustre/attribute.{action, class, for, href, method, name, required, type_}
import lustre/element
import lustre/element/html
import mist.{type Connection, type ResponseData}
import mistweaver/csrf
import mistweaver/flash
import mistweaver/middleware
import mistweaver/password
import mistweaver/request as mw_request
import mistweaver/response as mw_response
import mistweaver/session
import chirp/layout
import chirp/queries

// ---------------------------------------------------------------------------
// Register
// ---------------------------------------------------------------------------

pub fn register(
  repo: Repo,
  secret: String,
) -> fn(Request(Connection), List(#(String, String))) -> Response(ResponseData) {
  fn(req: Request(Connection), _params) {
    case req.method {
      Get -> register_page(req, secret)
      Post ->
        middleware.body_limit(4096, fn(req2) {
          handle_register(repo, req2, secret)
        })(req, fn(_) { mw_response.not_found() })
      _ -> mw_response.not_found()
    }
  }
}

fn register_page(
  req: Request(Connection),
  secret: String,
) -> Response(ResponseData) {
  let sess = session.get(req, secret)
  let #(csrf_token, updated_sess) = csrf.token_for(sess)
  let #(flash_opt, clear_flash) = flash.consume(req, secret)

  let content =
    html.div([class("auth-card")], [
      html.h1([], [html.text("Create your account")]),
      html.form([method("post"), action("/register"), class("form")], [
        csrf.hidden_input(csrf_token),
        html.div([class("field")], [
          html.label([for("username")], [html.text("Username")]),
          html.input([
            type_("text"),
            name("username"),
            required(True),
            attribute.attribute("placeholder", "e.g. gleam_dev"),
            attribute.attribute("maxlength", "32"),
          ]),
        ]),
        html.div([class("field")], [
          html.label([for("email")], [html.text("Email")]),
          html.input([type_("email"), name("email"), required(True)]),
        ]),
        html.div([class("field")], [
          html.label([for("password")], [html.text("Password")]),
          html.input([
            type_("password"),
            name("password"),
            required(True),
            attribute.attribute("minlength", "8"),
          ]),
        ]),
        html.button([type_("submit"), class("btn btn-primary full-width")], [
          html.text("Create account"),
        ]),
      ]),
      html.p([class("auth-link")], [
        html.text("Already have an account? "),
        html.a([href("/login")], [html.text("Sign in")]),
      ]),
    ])

  mw_response.html(
    200,
    element.to_document_string(
      layout.page(req, secret, "Register", flash_opt, content),
    ),
  )
  |> session.put(updated_sess, secret)
  |> clear_flash
}

fn handle_register(
  repo: Repo,
  req: Request(BitArray),
  secret: String,
) -> Response(ResponseData) {
  let sess = session.get(req, secret)
  let params = mw_request.form_params(req)

  case csrf.validate(params, sess) {
    False ->
      mw_response.redirect(302, to: "/register")
      |> flash.put(secret, "error", "Invalid form submission. Please try again.")
    True -> {
      let username =
        mw_request.form_param(params, "username") |> option.unwrap("")
      let email = mw_request.form_param(params, "email") |> option.unwrap("")
      let pw = mw_request.form_param(params, "password") |> option.unwrap("")

      case valid_username(username), valid_email(email), string.length(pw) >= 8 {
        False, _, _ ->
          mw_response.redirect(302, to: "/register")
          |> flash.put(
            secret,
            "error",
            "Username must be 1–32 characters: letters, numbers, _ or -",
          )
        _, False, _ ->
          mw_response.redirect(302, to: "/register")
          |> flash.put(secret, "error", "Please enter a valid email address.")
        _, _, False ->
          mw_response.redirect(302, to: "/register")
          |> flash.put(secret, "error", "Password must be at least 8 characters.")
        True, True, True ->
          case queries.create_user(repo, username, email, password.hash(pw)) {
            Ok(user) -> {
              let new_sess =
                session.empty()
                |> session.set("user_id", int.to_string(user.id))
                |> session.set("username", user.username)
              mw_response.redirect(302, to: "/timeline")
              |> session.put(new_sess, secret)
              |> flash.put(
                secret,
                "success",
                "Welcome to Chirp, @" <> user.username <> "!",
              )
            }
            Error(_) ->
              mw_response.redirect(302, to: "/register")
              |> flash.put(secret, "error", "That username or email is already taken.")
          }
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Login
// ---------------------------------------------------------------------------

pub fn login(
  repo: Repo,
  secret: String,
) -> fn(Request(Connection), List(#(String, String))) -> Response(ResponseData) {
  fn(req: Request(Connection), _params) {
    case req.method {
      Get -> login_page(req, secret)
      Post ->
        middleware.body_limit(4096, fn(req2) {
          handle_login(repo, req2, secret)
        })(req, fn(_) { mw_response.not_found() })
      _ -> mw_response.not_found()
    }
  }
}

fn login_page(
  req: Request(Connection),
  secret: String,
) -> Response(ResponseData) {
  let sess = session.get(req, secret)
  let #(csrf_token, updated_sess) = csrf.token_for(sess)
  let #(flash_opt, clear_flash) = flash.consume(req, secret)

  let content =
    html.div([class("auth-card")], [
      html.h1([], [html.text("Sign in to Chirp")]),
      html.form([method("post"), action("/login"), class("form")], [
        csrf.hidden_input(csrf_token),
        html.div([class("field")], [
          html.label([for("email")], [html.text("Email")]),
          html.input([type_("email"), name("email"), required(True)]),
        ]),
        html.div([class("field")], [
          html.label([for("password")], [html.text("Password")]),
          html.input([type_("password"), name("password"), required(True)]),
        ]),
        html.button([type_("submit"), class("btn btn-primary full-width")], [
          html.text("Sign in"),
        ]),
      ]),
      html.p([class("auth-link")], [
        html.text("No account yet? "),
        html.a([href("/register")], [html.text("Join Chirp")]),
      ]),
    ])

  mw_response.html(
    200,
    element.to_document_string(
      layout.page(req, secret, "Sign in", flash_opt, content),
    ),
  )
  |> session.put(updated_sess, secret)
  |> clear_flash
}

fn handle_login(
  repo: Repo,
  req: Request(BitArray),
  secret: String,
) -> Response(ResponseData) {
  let sess = session.get(req, secret)
  let params = mw_request.form_params(req)

  case csrf.validate(params, sess) {
    False ->
      mw_response.redirect(302, to: "/login")
      |> flash.put(secret, "error", "Invalid form submission. Please try again.")
    True -> {
      let email = mw_request.form_param(params, "email") |> option.unwrap("")
      let pw = mw_request.form_param(params, "password") |> option.unwrap("")

      case queries.find_user_by_email(repo, email) {
        Ok(user) ->
          case password.verify(pw, user.password_hash) {
            True -> {
              let new_sess =
                session.empty()
                |> session.set("user_id", int.to_string(user.id))
                |> session.set("username", user.username)
              mw_response.redirect(302, to: "/timeline")
              |> session.put(new_sess, secret)
            }
            False ->
              mw_response.redirect(302, to: "/login")
              |> flash.put(secret, "error", "Invalid email or password.")
          }
        Error(_) ->
          mw_response.redirect(302, to: "/login")
          |> flash.put(secret, "error", "Invalid email or password.")
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Logout
// ---------------------------------------------------------------------------

pub fn logout(
  _repo: Repo,
  secret: String,
) -> fn(Request(Connection), List(#(String, String))) -> Response(ResponseData) {
  fn(_req: Request(Connection), _params) {
    mw_response.redirect(302, to: "/login")
    |> session.delete
    |> flash.put(secret, "success", "You've been signed out.")
  }
}

// ---------------------------------------------------------------------------
// Validation helpers
// ---------------------------------------------------------------------------

fn valid_username(username: String) -> Bool {
  let len = string.length(username)
  len >= 1
  && len <= 32
  && list.all(string.to_graphemes(username), fn(c) {
    string.contains(
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-",
      c,
    )
  })
}

fn valid_email(email: String) -> Bool {
  case string.split_once(email, "@") {
    Ok(#(local, domain)) ->
      !string.is_empty(local)
      && string.contains(domain, ".")
      && string.length(domain) > 2
    Error(_) -> False
  }
}
