import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gloo/repo.{type Repo}
import lustre/attribute.{class}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import mistweaver/live.{type LiveView}
import chirp/queries
import chirp/schema.{type ChirpWithAuthor}

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

pub type Model {
  Model(
    chirps: List(ChirpWithAuthor),
    new_body: String,
    current_user_id: option.Option(Int),
    current_username: option.Option(String),
  )
}

// ---------------------------------------------------------------------------
// Messages
// ---------------------------------------------------------------------------

pub type Msg {
  SetBody(String)
  SubmitChirp
  ChirpPosted(schema.Chirp)
  Refresh
  GotChirps(List(ChirpWithAuthor))
}

// ---------------------------------------------------------------------------
// LiveView factory — context is injected directly, no URL param tricks
// ---------------------------------------------------------------------------

/// Build a timeline LiveView that closes over the repo and the current user.
/// Called per-request from `live.dynamic_handler_with_shell` so the user
/// context comes from the real session cookie, not from URL params.
pub fn make(
  repo: Repo,
  user_id: option.Option(Int),
  username: option.Option(String),
) -> LiveView(Model, Msg) {
  live.LiveView(
    init: fn(_params) { init(repo, user_id, username) },
    update: make_update(repo),
    view: view,
  )
}

// ---------------------------------------------------------------------------
// Init
// ---------------------------------------------------------------------------

fn init(
  repo: Repo,
  user_id: option.Option(Int),
  username: option.Option(String),
) -> #(Model, Effect(Msg)) {
  let chirps = case queries.recent_chirps(repo, 50) {
    Ok(cs) -> cs
    Error(_) -> []
  }
  #(
    Model(
      chirps: chirps,
      new_body: "",
      current_user_id: user_id,
      current_username: username,
    ),
    effect.none(),
  )
}

// ---------------------------------------------------------------------------
// Update
// ---------------------------------------------------------------------------

fn make_update(repo: Repo) -> fn(Model, Msg) -> #(Model, Effect(Msg)) {
  fn(model, msg) {
    case msg {
      SetBody(body) -> #(Model(..model, new_body: body), effect.none())

      SubmitChirp -> {
        let trimmed = string.trim(model.new_body)
        let len = string.length(trimmed)
        case model.current_user_id, trimmed {
          Some(uid), body if body != "" && len <= 280 ->
            #(model, post_chirp(repo, uid, body))
          _, _ -> #(model, effect.none())
        }
      }

      ChirpPosted(chirp) -> {
        let author = model.current_username |> option.unwrap("unknown")
        let with_author =
          schema.ChirpWithAuthor(
            id: chirp.id,
            body: chirp.body,
            inserted_at: chirp.inserted_at,
            username: author,
          )
        #(
          Model(..model, chirps: [with_author, ..model.chirps], new_body: ""),
          effect.none(),
        )
      }

      Refresh -> #(model, refresh_chirps(repo))

      GotChirps(chirps) -> #(Model(..model, chirps: chirps), effect.none())
    }
  }
}

// ---------------------------------------------------------------------------
// Effects
// ---------------------------------------------------------------------------

fn post_chirp(repo: Repo, user_id: Int, body: String) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    case queries.create_chirp(repo, user_id, body) {
      Ok(chirp) -> dispatch(ChirpPosted(chirp))
      Error(_) -> Nil
    }
  })
}

fn refresh_chirps(repo: Repo) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    case queries.recent_chirps(repo, 50) {
      Ok(chirps) -> dispatch(GotChirps(chirps))
      Error(_) -> Nil
    }
  })
}

// ---------------------------------------------------------------------------
// View
// ---------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  html.div([class("timeline")], [
    case model.current_user_id {
      Some(_) -> compose_box(model)
      None ->
        html.div([class("login-prompt")], [
          html.a([attribute.href("/login"), class("btn btn-primary")], [
            html.text("Sign in to post a chirp"),
          ]),
        ])
    },
    html.div([class("chirp-list")], list.map(model.chirps, chirp_card)),
    html.div([class("refresh-bar")], [
      html.button([class("btn btn-ghost"), event.on_click(Refresh)], [
        html.text("↻ Refresh"),
      ]),
    ]),
  ])
}

fn compose_box(model: Model) -> Element(Msg) {
  html.div([class("compose")], [
    html.textarea(
      [
        class("compose-input"),
        attribute.attribute("placeholder", "What's happening?"),
        attribute.attribute("maxlength", "280"),
        attribute.attribute("rows", "3"),
        event.on_input(SetBody),
        attribute.value(model.new_body),
      ],
      "",
    ),
    html.div([class("compose-footer")], [
      html.span([class("char-count")], [
        html.text(
          int.to_string(280 - string.length(model.new_body)) <> " left",
        ),
      ]),
      html.button([class("btn btn-primary"), event.on_click(SubmitChirp)], [
        html.text("Chirp"),
      ]),
    ]),
  ])
}

fn chirp_card(chirp: ChirpWithAuthor) -> Element(Msg) {
  html.article([class("chirp-card")], [
    html.div([class("chirp-header")], [
      html.a(
        [attribute.href("/users/" <> chirp.username), class("chirp-author")],
        [html.text("@" <> chirp.username)],
      ),
      html.span([class("chirp-time")], [html.text(chirp.inserted_at)]),
    ]),
    html.p([class("chirp-body")], [html.text(chirp.body)]),
  ])
}
