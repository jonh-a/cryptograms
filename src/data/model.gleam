pub type Model {
  Model(
    author: String,
    char_list: List(#(String, Int)),
    space_delimited_char_list_with_indexes: List(List(#(String, Int, Int))),
    answer: String,
    guess: List(String),
    selected_char: String,
    solved: Bool,
    start_time: Int,
    solve_time: Int,
    hints: Int,
  )
}
