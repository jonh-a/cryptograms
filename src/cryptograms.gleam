import answers.{get_random_answer}
import gleam/int
import gleam/io
import gleam/option.{None}
import gleam/string
import gleam/uri.{type Uri}
import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import modem
import util.{decode, get_initial_route, get_unix_time_now}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Model {
  Model(
    current_route: String,
    answer: String,
    guess: String,
    solved: Bool,
    start_time: Int,
    solve_time: Int,
  )
}

fn redirect_to_valid_puzzle() -> #(Model, Effect(Msg)) {
  let puzzle = get_random_answer()
  #(compute_route(puzzle), modem.push(puzzle, None, None))
}

fn init(_flags) -> #(Model, Effect(Msg)) {
  let initial_route = get_initial_route()
  io.debug(initial_route)

  case initial_route {
    "localhost:1234" | "cryptograms.usingthe.computer" ->
      redirect_to_valid_puzzle()
    _ -> #(compute_route(initial_route), modem.init(on_url_change))
  }
}

fn on_url_change(_: Uri) -> Msg {
  let route = get_initial_route()
  OnRouteChange(route)
}

fn handle_button_click(model: Model) -> Model {
  case model.solved {
    False -> Model(..model, solve_time: get_unix_time_now(), solved: True)
    True ->
      Model(
        ..model,
        start_time: get_unix_time_now(),
        solve_time: 0,
        solved: False,
      )
  }
}

fn compute_route(route: String) -> Model {
  Model(
    current_route: route,
    start_time: get_unix_time_now(),
    solve_time: 0,
    solved: False,
    guess: "",
    answer: decode(route),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    Submit -> #(handle_button_click(model), effect.none())
    OnRouteChange(route) -> #(compute_route(route), effect.none())
  }
}

type Msg {
  OnRouteChange(String)
  Submit
}

fn view(model: Model) -> Element(Msg) {
  let button_text = case model.solved {
    True -> "reset"
    False -> "guess"
  }

  html.div([], [
    html.h1([], [element.text("Current route: " <> model.answer)]),
    case model.solved {
      True -> int.to_string(model.solve_time - model.start_time)
      False -> ""
    }
      |> element.text(),
    html.button([event.on_click(Submit)], [element.text(button_text)]),
  ])
}
