import data/model.{type SolutionStatistics}
import lustre_http.{type HttpError}

pub type Msg {
  UserClickedSubmit
  UserClickedPlayAnother
  UserFocusedCharacter(char: String)
  UserGuessedCharacter(value: String, index: Int)
  UserPressedKey(key: String, index: Int)
  UserRequestedHint
  BackendProvidedResponse(Result(SolutionStatistics, HttpError))
}
