import gleam/list

pub fn get_random_answer() {
  ["asdf", "fdsa", "sdfg"]
  |> list.shuffle()
  |> list.first()
  |> fn(x) {
    case x {
      Ok(item) -> item
      Error(_) -> ""
    }
  }
}
