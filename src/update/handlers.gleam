import data/model.{type Model, type SolutionStatistics, Model}
import data/msg.{type Msg}
import gleam/int
import gleam/option.{None, Some}
import gleam/string
import http.{submit_solve_statistics}
import lustre/effect.{type Effect}
import lustre_http.{type HttpError}
import puzzles.{get_random_answer}
import util.{
  check_if_solved, decode, get_item_at_index, get_last_character,
  get_space_delimited_char_list_with_indexes, get_unix_time_now,
  initialize_guess, is_letter, move_to_next_empty_field, move_to_next_field,
  move_to_previous_field, provide_hint, replace_all_matching_chars_with_new_char,
  shuffle_alphabet, string_to_letter_frequency,
}

pub fn init(_flags) -> #(Model, Effect(Msg)) {
  let puzzle = get_random_answer()
  #(compute_model(puzzle), effect.none())
}

pub fn compute_model(puzzle: #(String, String)) -> Model {
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
    shuffled_alphabet: shuffle_alphabet(),
    solution_statistics: None,
  )
}

pub fn handle_user_guessed_character(
  model: Model,
  key: String,
  index: Int,
) -> Model {
  let key_pressed_was_letter = key |> get_last_character() |> is_letter()

  let next_input_id = case key_pressed_was_letter {
    True -> move_to_next_empty_field(index + 1 |> int.to_string())
    _ -> move_to_next_field(index |> int.to_string())
  }

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

pub fn handle_user_focused_character(model: Model, char: String) -> Model {
  Model(..model, selected_char: char)
}

pub fn handle_user_clicked_play_another() -> #(Model, Effect(Msg)) {
  init([])
}

pub fn handle_user_requested_hint(model: Model) -> Model {
  let hint_count = model.hints + 1

  case hint_count < 6 {
    True ->
      Model(
        ..model,
        guess: provide_hint(model.answer, model.guess, hint_count),
        hints: hint_count,
      )

    False -> model
  }
}

pub fn handle_button_click(model: Model) -> #(Model, Effect(Msg)) {
  case check_if_solved(model.guess, model.answer) {
    True -> #(
      Model(..model, solve_time: get_unix_time_now(), solved: True),
      submit_solve_statistics(model),
    )
    False -> #(model, effect.none())
  }
}

/// keydown events triggers for arrow key & enter movement, so
/// we have a separate handler for it. this also handles replacing
/// the current highlighted character if a key is provided.
pub fn handle_user_pressed_key(
  model: Model,
  key: String,
  index: Int,
) -> #(Model, Effect(Msg)) {
  let should_replace_current_value =
    key |> is_letter()
    && string.length(get_item_at_index(model.guess, index)) > 0

  let next_input_id = case key {
    "ArrowRight" -> move_to_next_field(index + 1 |> int.to_string())
    "ArrowLeft" -> move_to_previous_field(index |> int.to_string())
    _ -> move_to_next_field(index |> int.to_string())
  }

  let new_selected_char =
    model.answer |> string.to_graphemes() |> get_item_at_index(next_input_id)

  case key, should_replace_current_value {
    "Backspace", _ -> #(
      Model(
        ..model,
        selected_char: new_selected_char,
        guess: replace_all_matching_chars_with_new_char(
          model.char_list,
          model.guess,
          index,
          "",
        ),
      ),
      effect.none(),
    )
    "Enter", _ -> handle_button_click(model)
    "]", _ -> #(handle_user_requested_hint(model), effect.none())
    _, True -> #(
      Model(
        ..model,
        selected_char: new_selected_char,
        guess: replace_all_matching_chars_with_new_char(
          model.char_list,
          model.guess,
          index,
          key,
        ),
      ),
      effect.none(),
    )
    _, _ -> #(Model(..model, selected_char: new_selected_char), effect.none())
  }
}

pub fn handle_backend_provided_response(
  model: Model,
  result: Result(SolutionStatistics, HttpError),
) {
  case result {
    Ok(result) -> Model(..model, solution_statistics: Some(result))
    Error(_) -> Model(..model, solution_statistics: None)
  }
}
