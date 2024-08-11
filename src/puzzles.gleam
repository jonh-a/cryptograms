import gleam/list
import gleam/result

pub fn get_random_answer() {
  [
    #("dGhpcyBpcyBhIHRlc3Qu", "test"),
    #(
      "SW4gcmVhbCBsaWZlLCBJIGFzc3VyZSB5b3UsIHRoZXJlIGlzIG5vIHN1Y2ggdGhpbmcgYXMgYWxnZWJyYS4",
      "Fran Lebowitz",
    ),
  ]
  |> list.shuffle()
  |> list.first()
  |> result.unwrap(#("", ""))
}
