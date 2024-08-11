import data/model.{type Model, Model}
import data/msg.{type Msg}
import gleam/int
import gleam/io
import gleam/string
import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import puzzles.{get_random_answer}
import util.{
  check_if_solved, decode, get_item_at_index, get_last_character,
  get_space_delimited_char_list_with_indexes, get_unix_time_now,
  initialize_guess, is_letter, move_to_next_field, provide_hint,
  replace_all_matching_chars_with_new_char, string_to_letter_frequency,
}
import view/cryptogram.{show_cryptogram}
import view/solved.{show_solved}

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
  let key_pressed_was_letter = key |> get_last_character() |> is_letter()

  let next_input_id = case key_pressed_was_letter {
    True -> move_to_next_field(index + 1 |> int.to_string())
    _ -> move_to_next_field(index |> int.to_string())
  }

  io.debug(next_input_id)

  let new_selected_char =
    model.answer |> string.to_graphemes() |> get_item_at_index(next_input_id)

  case key_pressed_was_letter, key {
    True, _ | False, "" ->
      Model(
        ..model,
        selected_char: new_selected_char,
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
    msg.UserClickedSubmit -> #(handle_button_click(model), effect.none())
    msg.UserGuessedCharacter(value, index) -> #(
      handle_user_guessed_character(model, value, index),
      effect.none(),
    )
    msg.UserFocusedCharacter(char) -> #(
      handle_user_focused_character(model, char),
      effect.none(),
    )
    msg.UserClickedPlayAnother -> handle_user_clicked_play_another()
    msg.UserRequestedHint -> handle_user_requested_hint(model)
  }
}

fn view(model: Model) -> Element(Msg) {
  io.debug(model)

  case model.solved {
    True -> show_solved(model)
    False -> show_cryptogram(model)
  }
}
