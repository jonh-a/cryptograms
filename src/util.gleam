import birl
import gleam/bit_array
import gleam/io
import gleam/list
import gleam/string
import gleam/uri.{type Uri}
import modem

pub fn get_unix_time_now() -> Int {
  birl.utc_now()
  |> birl.to_unix()
}

pub fn parse_path(uri: Uri) -> String {
  uri
  |> uri.to_string()
  |> uri.path_segments()
  |> list.last()
  |> fn(x) {
    case x {
      Ok(i) -> i
      Error(_) -> ""
    }
  }
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

pub fn get_initial_route() -> String {
  let initial_uri = modem.initial_uri()

  case initial_uri {
    Ok(route) -> parse_path(route)
    _ -> ""
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

pub fn is_letter(char: String) -> Bool {
  [
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o",
    "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
  ]
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
  |> fn(x) {
    case x {
      Ok(last) -> last
      _ -> ""
    }
  }
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
  guess == answer |> string.to_graphemes()
}
