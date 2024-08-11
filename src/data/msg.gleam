pub type Msg {
  UserClickedSubmit
  UserClickedPlayAnother
  UserFocusedCharacter(char: String)
  UserGuessedCharacter(value: String, index: Int)
  UserPressedKey(key: String, index: Int)
  UserRequestedHint
}
