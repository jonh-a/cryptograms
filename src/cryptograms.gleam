import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None}
import gleam/string
import gleam/uri.{type Uri}
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import lustre/ui
import modem
import puzzles.{get_random_answer}
import util.{
  decode, get_initial_route, get_item_at_index, get_last_character,
  get_unix_time_now, initialize_guess, insert_char_at_index_in_list, is_letter,
  string_to_letter_frequency,
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Model {
  Model(
    current_route: String,
    char_array: List(#(String, Int)),
    answer: String,
    guess: List(String),
    selected_char: String,
    solved: Bool,
    start_time: Int,
    solve_time: Int,
  )
}

fn redirect_to_valid_puzzle() -> #(Model, Effect(Msg)) {
  let puzzle = get_random_answer()
  #(compute_model(puzzle), modem.push(puzzle, None, None))
}

fn init(_flags) -> #(Model, Effect(Msg)) {
  let initial_route = get_initial_route()
  io.debug(initial_route)

  case initial_route {
    "localhost:1234" | "cryptograms.usingthe.computer" ->
      redirect_to_valid_puzzle()
    _ -> #(compute_model(initial_route), modem.init(on_url_change))
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

fn compute_model(route: String) -> Model {
  let decoded = decode(route)
  let char_array = string_to_letter_frequency(decoded)

  Model(
    current_route: route,
    start_time: get_unix_time_now(),
    char_array: char_array,
    selected_char: "",
    solve_time: 0,
    solved: False,
    guess: initialize_guess(char_array),
    answer: decoded,
  )
}

fn handle_user_guessed_character(model: Model, key: String, index: Int) -> Model {
  io.debug(#(key, index))
  case key |> get_last_character() |> is_letter(), key {
    True, _ | False, "" ->
      Model(
        ..model,
        guess: insert_char_at_index_in_list(model.guess, key, index),
      )
    False, _ -> Model(..model)
  }
}

fn handle_user_clicked_character(model: Model, char: String) -> Model {
  Model(..model, selected_char: char)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserClickedSubmit -> #(handle_button_click(model), effect.none())
    OnRouteChange(route) -> #(compute_model(route), effect.none())
    UserGuessedCharacter(value, index) -> #(
      handle_user_guessed_character(model, value, index),
      effect.none(),
    )
    UserClickedCharacter(char) -> #(
      handle_user_clicked_character(model, char),
      effect.none(),
    )
  }
}

type Msg {
  OnRouteChange(String)
  UserClickedSubmit
  UserClickedCharacter(char: String)
  UserGuessedCharacter(value: String, index: Int)
}

fn view(model: Model) -> Element(Msg) {
  io.debug(model)
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
    html.div(
      [],
      list.index_map(model.char_array, fn(char: #(String, Int), index: Int) {
        show_char(model, char, index)
      }),
    ),
    html.button([event.on_click(UserClickedSubmit)], [element.text(button_text)]),
  ])
}

fn show_char(model: Model, char: #(String, Int), index: Int) {
  let background_color = case model.selected_char == char.0 {
    True -> "yellow"
    False -> "none"
  }

  case is_letter(char.0) {
    True ->
      html.span([], [
        ui.input([
          attribute.id(index |> int.to_string()),
          event.on_input(fn(key: String) { UserGuessedCharacter(key, index) }),
          attribute.value(model.guess |> get_item_at_index(index)),
          event.on_click(UserClickedCharacter(char.0)),
          attribute.style([
            #("background-color", background_color),
            #("width", "1em"),
          ]),
        ]),
        html.label([attribute.for(index |> int.to_string())], [
          element.text(char.1 |> int.to_string()),
        ]),
      ])
    False -> html.span([], [element.text(char.0)])
  }
}
