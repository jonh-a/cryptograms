import gleam/list

pub fn get_random_answer() {
  ["dGhpcyBpcyBhIHRlc3Qu"]
  |> list.shuffle()
  |> list.first()
  |> fn(x) {
    case x {
      Ok(item) -> item
      Error(_) -> ""
    }
  }
}
