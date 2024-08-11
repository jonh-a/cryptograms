import birl
import gleam/bit_array
import gleam/list
import gleam/result
import gleam/string
import gleam/uri.{type Uri}

pub fn get_unix_time_now() -> Int {
  birl.utc_now()
  |> birl.to_unix()
}

pub fn parse_path(uri: Uri) -> String {
  uri
  |> uri.to_string()
  |> uri.path_segments()
  |> list.last()
  |> result.unwrap("")
}

pub type Mode {
  Play
  Share
}

pub fn determine_mode_from_uri(uri: Uri) -> Mode {
  uri
  |> uri.to_string()
  |> uri.path_segments()
  |> list.first()
  |> fn(x) {
    case x {
      Ok("play") -> Play
      Ok("share") -> Share
      Ok(_) | Error(_) -> Play
    }
  }
}

pub fn decode(string: String) -> String {
  case bit_array.base64_decode(string) {
    Ok(decoded) ->
      case bit_array.to_string(decoded) {
        Ok(decoded_string) -> decoded_string
        _ -> ""
      }
    _ -> ""
  }
}

pub fn string_to_letter_frequency(string: String) -> List(#(String, Int)) {
  let char_array = string |> string.to_graphemes()
  list.map(char_array, fn(character) {
    #(character, list.count(char_array, fn(x) { x == character }))
  })
}

fn alphabet() -> List(String) {
  [
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o",
    "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
  ]
}

pub fn is_letter(char: String) -> Bool {
  alphabet()
  |> list.contains(string.lowercase(char))
}

pub fn initialize_guess(char_array: List(#(String, Int))) -> List(String) {
  char_array
  |> list.map(fn(char: #(String, Int)) {
    case is_letter(char.0 |> string.lowercase) {
      True -> ""
      False -> char.0
    }
  })
}

pub fn get_last_character(string: String) -> String {
  string
  |> string.to_graphemes()
  |> list.last()
  |> result.unwrap("")
  |> string.lowercase()
}

pub fn get_item_at_index(l: List(String), index: Int) -> String {
  case list.drop(l, index) {
    [head, ..] -> head
    _ -> ""
  }
}

pub fn find_indexes_of_matching_chars(
  answer_list: List(#(String, Int)),
  index: Int,
) -> List(Int) {
  let answer_list_with_chars_only = list.map(answer_list, fn(item) { item.0 })
  let indexed_char = get_item_at_index(answer_list_with_chars_only, index)
  list.index_map(answer_list_with_chars_only, fn(item: String, index: Int) {
    #(item, index)
  })
  |> list.key_filter(indexed_char)
}

pub fn replace_all_matching_chars_with_new_char(
  answer_list: List(#(String, Int)),
  guess: List(String),
  index: Int,
  new_char: String,
) -> List(String) {
  let indexes_to_replace = find_indexes_of_matching_chars(answer_list, index)
  list.index_map(guess, fn(item: String, index: Int) {
    case list.contains(indexes_to_replace, index) {
      True -> get_last_character(new_char)
      False -> item
    }
  })
}

pub fn check_if_solved(guess: List(String), answer: String) {
  guess == answer |> string.lowercase() |> string.to_graphemes()
}

pub fn get_space_delimited_char_list_with_indexes(
  char_list: List(#(String, Int)),
) -> List(List(#(String, Int, Int))) {
  char_list
  |> get_char_list_with_index()
  |> chunk_on_space()
}

fn get_char_list_with_index(char_list: List(#(String, Int))) {
  add_index_to_char(char_list, [], 0)
}

fn add_index_to_char(
  char_list: List(#(String, Int)),
  acc: List(#(String, Int, Int)),
  index: Int,
) {
  case char_list {
    [head, ..tail] ->
      add_index_to_char(
        tail,
        list.append(acc, [#(head.0, head.1, index)]),
        index + 1,
      )
    [] -> acc
  }
}

fn chunk_on_space(
  input_list: List(#(String, Int, Int)),
) -> List(List(#(String, Int, Int))) {
  chunk_on_space_helper(input_list, [[]])
}

fn chunk_on_space_helper(
  input_list: List(#(String, Int, Int)),
  acc: List(List(#(String, Int, Int))),
) -> List(List(#(String, Int, Int))) {
  // thanks chatgpt
  case input_list {
    [] -> acc |> list.reverse |> list.map(list.reverse)
    [head, ..tail] ->
      case head {
        #(" ", _, _) -> chunk_on_space_helper(tail, [[], ..acc])
        _ -> {
          let updated_acc = case acc {
            [current_chunk, ..rest] -> [[head, ..current_chunk], ..rest]
            _ -> acc
          }
          chunk_on_space_helper(tail, updated_acc)
        }
      }
  }
}

pub fn provide_hint(
  answer: String,
  guess_chars: List(String),
  hints: Int,
) -> List(String) {
  let hint_letters =
    ["a", "e", "i", "o", "u"]
    |> list.take(hints)

  let answer_chars = answer |> string.to_graphemes()

  list.map2(
    answer_chars,
    guess_chars,
    fn(answer_char: String, guess_char: String) {
      case list.contains(hint_letters, answer_char) {
        True -> answer_char
        False -> guess_char
      }
    },
  )
}

pub fn shuffle_alphabet() -> List(#(String, String)) {
  let alphabet = alphabet()
  let shuffled = list.shuffle(alphabet)
  list.zip(alphabet, shuffled)
}

@external(javascript, "./cryptograms_ffi.mjs", "moveToNextEmptyField")
pub fn move_to_next_empty_field(next_field_id: String) -> Int

@external(javascript, "./cryptograms_ffi.mjs", "moveToNextField")
pub fn move_to_next_field(next_field_id: String) -> Int

@external(javascript, "./cryptograms_ffi.mjs", "moveToPreviousField")
pub fn move_to_previous_field(next_field_id: String) -> Int
