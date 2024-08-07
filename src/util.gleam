import birl
import gleam/list
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
