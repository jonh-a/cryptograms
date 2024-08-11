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
  check_if_solved, decode, get_initial_route, get_item_at_index,
  get_last_character, get_space_delimited_char_list_with_indexes,
  get_unix_time_now, initialize_guess, is_letter,
  replace_all_matching_chars_with_new_char, string_to_letter_frequency,
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Model {
  Model(
    current_route: String,
    char_list: List(#(String, Int)),
    space_delimited_char_list_with_indexes: List(List(#(String, Int, Int))),
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
    False ->
      case check_if_solved(model.guess, model.answer) {
        True -> Model(..model, solve_time: get_unix_time_now(), solved: True)
        False -> Model(..model)
      }

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
  let char_list = string_to_letter_frequency(decoded)

  Model(
    current_route: route,
    start_time: get_unix_time_now(),
    char_list: char_list,
    space_delimited_char_list_with_indexes: get_space_delimited_char_list_with_indexes(
      char_list,
    ),
    selected_char: "",
    solve_time: 0,
    solved: False,
    guess: initialize_guess(char_list),
    answer: decoded,
  )
}

fn handle_user_guessed_character(model: Model, key: String, index: Int) -> Model {
  io.debug(#(key, index))
  case key |> get_last_character() |> is_letter(), key {
    True, _ | False, "" ->
      Model(
        ..model,
        guess: replace_all_matching_chars_with_new_char(
          model.char_list,
          model.guess,
          index,
          key,
        ),
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

  show_cryptogram(model, button_text)
}

fn show_cryptogram(model: Model, button_text: String) {
  html.div([], [
    html.h1([], [element.text("Current route: " <> model.answer)]),
    case model.solved {
      True -> int.to_string(model.solve_time - model.start_time)
      False -> ""
    }
      |> element.text(),
    ui.centre(
      [],
      ui.cluster(
        [],
        list.map(
          model.space_delimited_char_list_with_indexes,
          fn(word: List(#(String, Int, Int))) { show_word(model, word) },
        ),
      ),
    ),
    ui.button([event.on_click(UserClickedSubmit)], [element.text(button_text)]),
  ])
}

fn show_word(model: Model, word: List(#(String, Int, Int))) {
  ui.cluster(
    [],
    list.append(
      list.map(word, fn(char: #(String, Int, Int)) { show_char(model, char) }),
      [show_space()],
    ),
  )
}

fn show_char(model: Model, char: #(String, Int, Int)) {
  let index = char.2
  let background_color = case model.selected_char == char.0 {
    True -> "yellow"
    False -> "none"
  }

  case is_letter(char.0) {
    True ->
      ui.field(
        [],
        [],
        ui.input([
          attribute.autocomplete("off"),
          attribute.id(index |> int.to_string()),
          attribute.value(model.guess |> get_item_at_index(index)),
          event.on_input(fn(key: String) { UserGuessedCharacter(key, index) }),
          event.on_click(UserClickedCharacter(char.0)),
          attribute.style([
            #("background-color", background_color),
            #("width", "2.5em"),
          ]),
        ]),
        [element.text(char.1 |> int.to_string())],
      )
    False -> html.span([], [element.text(char.0)])
  }
}

fn show_space() -> Element(a) {
  html.span([attribute.style([#("padding-left", "1em")])], [element.text(" ")])
}
