pub type Model {
  Model(
    author: String,
    // list of characters and their frequency
    char_list: List(#(String, Int)),
    // list of sub-lists containing characters, frequency, and index
    space_delimited_char_list_with_indexes: List(List(#(String, Int, Int))),
    // solution as string
    answer: String,
    // guess as a character list
    guess: List(String),
    // character to be highlighted
    selected_char: String,
    solved: Bool,
    start_time: Int,
    solve_time: Int,
    // number of hints used
    hints: Int,
  )
}
