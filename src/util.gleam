import birl
import gleam/bit_array
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
