import gleam/dict.{type Dict}
import gleam/http/request.{type Request}
import gleam/option.{type Option, None}

pub type AuthUser {
  AuthUser(id: Int, username: String)
}

pub type Conn(body) {
  Conn(
    request: Request(body),
    auth: Option(AuthUser),
    assigns: Dict(String, String),
  )
}

pub fn new(req: Request(body)) -> Conn(body) {
  Conn(request: req, auth: None, assigns: dict.new())
}
