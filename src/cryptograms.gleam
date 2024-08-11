import gleam/int
import gleam/io
import gleam/list
import gleam/string
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import lustre/ui
import model.{type Model, Model}
import puzzles.{get_random_answer}
import util.{
  check_if_solved, decode, get_item_at_index, get_last_character,
  get_space_delimited_char_list_with_indexes, get_unix_time_now,
  initialize_guess, is_letter, provide_hint,
  replace_all_matching_chars_with_new_char, string_to_letter_frequency,
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

fn init(_flags) -> #(Model, Effect(Msg)) {
  let puzzle = get_random_answer()
  #(compute_model(puzzle), effect.none())
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

fn compute_model(puzzle: #(String, String)) -> Model {
  let decoded = decode(puzzle.0) |> string.lowercase()
  let char_list = string_to_letter_frequency(decoded)

  Model(
    author: puzzle.1,
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
    hints: 0,
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

fn handle_user_focused_character(model: Model, char: String) -> Model {
  Model(..model, selected_char: char)
}

fn handle_user_clicked_play_another() -> #(Model, Effect(Msg)) {
  init([])
}

fn handle_user_requested_hint(model: Model) -> #(Model, Effect(Msg)) {
  let hint_count = model.hints + 1

  case hint_count < 6 {
    True -> #(
      Model(
        ..model,
        guess: provide_hint(model.answer, model.guess, hint_count),
        hints: hint_count,
      ),
      effect.none(),
    )
    False -> #(model, effect.none())
  }
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserClickedSubmit -> #(handle_button_click(model), effect.none())
    UserGuessedCharacter(value, index) -> #(
      handle_user_guessed_character(model, value, index),
      effect.none(),
    )
    UserFocusedCharacter(char) -> #(
      handle_user_focused_character(model, char),
      effect.none(),
    )
    UserClickedPlayAnother -> handle_user_clicked_play_another()
    UserRequestedHint -> handle_user_requested_hint(model)
  }
}

type Msg {
  UserClickedSubmit
  UserClickedPlayAnother
  UserFocusedCharacter(char: String)
  UserGuessedCharacter(value: String, index: Int)
  UserRequestedHint
}

fn view(model: Model) -> Element(Msg) {
  io.debug(model)

  case model.solved {
    True -> show_solved(model)
    False -> show_cryptogram(model)
  }
}

fn show_solved(model: Model) -> Element(Msg) {
  let solved_time = model.solve_time - model.start_time
  ui.centre(
    [],
    html.div([], [
      html.h1([], [element.text(model.answer)]),
      html.h2([], [
        element.text("solved in " <> int.to_string(solved_time) <> " seconds"),
      ]),
      ui.button([event.on_click(UserClickedPlayAnother)], [
        element.text("play another"),
      ]),
    ]),
  )
}

fn show_cryptogram(model: Model) -> Element(Msg) {
  let hint_button_text = case model.hints < 5 {
    True -> "hint"
    False -> ":-("
  }

  ui.centre(
    [attribute.style([#("display", "flex")])],
    html.div(
      [attribute.style([#("padding-left", "3em"), #("padding-right", "3em")])],
      [
        html.h1(
          [
            attribute.style([
              #("margin-left", "auto"),
              #("margin-right", "auto"),
            ]),
          ],
          [element.text("quote by: " <> model.author)],
        ),
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
        ui.button([event.on_click(UserClickedSubmit)], [element.text("guess")]),
        ui.button(
          [
            attribute.disabled(model.hints > 5),
            event.on_click(UserRequestedHint),
          ],
          [element.text(hint_button_text)],
        ),
      ],
    ),
  )
}

fn show_word(model: Model, word: List(#(String, Int, Int))) -> Element(Msg) {
  ui.cluster(
    [],
    list.append(
      list.map(word, fn(char: #(String, Int, Int)) { show_char(model, char) }),
      [show_space()],
    ),
  )
}

fn show_char(model: Model, char: #(String, Int, Int)) -> Element(Msg) {
  let index = char.2
  let background_color = case model.selected_char == char.0 {
    True -> "yellow"
    False -> "none"
  }

  case is_letter(char.0) {
    True ->
      html.div([attribute.style([#("background-color", "lightgray")])], [
        ui.field(
          [],
          [],
          ui.input([
            attribute.autocomplete("off"),
            attribute.id(index |> int.to_string()),
            attribute.value(model.guess |> get_item_at_index(index)),
            event.on_input(fn(key: String) { UserGuessedCharacter(key, index) }),
            event.on_focus(UserFocusedCharacter(char.0)),
            attribute.style([
              #("background-color", background_color),
              #("font-size", ".9em"),
              #("width", "2.5em"),
              #("text-align", "center"),
              #("height", "2em"),
            ]),
          ]),
          [show_char_clue(char)],
        ),
      ])

    False ->
      html.span(
        [attribute.style([#("margin-top", "auto"), #("height", "100%")])],
        [element.text(char.0)],
      )
  }
}

fn show_char_clue(char: #(String, Int, Int)) -> Element(Msg) {
  html.div(
    [
      attribute.style([
        #("display", "flex"),
        #("flex-direction", "column"),
        #("align-items", "center"),
        #("margin-right", "auto"),
        #("margin-left", "auto"),
      ]),
    ],
    [
      html.p(
        [
          attribute.style([
            #("color", "black"),
            #("margin-bottom", "-.3em"),
            #("font-size", ".75em"),
          ]),
        ],
        [element.text("A")],
      ),
      html.p([attribute.style([#("color", "black"), #("font-size", ".6em")])], [
        element.text(char.1 |> int.to_string()),
      ]),
    ],
  )
}

fn show_space() -> Element(Msg) {
  html.span([attribute.style([#("padding-left", "1em")])], [element.text(" ")])
}
