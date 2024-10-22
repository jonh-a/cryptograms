import data/model.{type Model, Model}
import data/msg.{type Msg}
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import lustre/ui
import util.{get_item_at_index, is_letter}

pub fn show_cryptogram(model: Model) -> Element(Msg) {
  ui.centre(
    [attribute.style([#("display", "flex")])],
    html.div(
      [attribute.style([#("padding-left", "3em"), #("padding-right", "3em")])],
      [
        show_header(model),
        show_time(model),
        show_words(model),
        show_buttons(model),
      ],
    ),
  )
}

fn show_header(model: Model) -> Element(Msg) {
  html.h1(
    [attribute.style([#("margin-left", "auto"), #("margin-right", "auto")])],
    [element.text("quote by: " <> model.author)],
  )
}

fn show_time(model: Model) -> Element(Msg) {
  case model.solved {
    True -> int.to_string(model.solve_time - model.start_time)
    False -> ""
  }
  |> element.text()
}

fn show_words(model: Model) -> Element(Msg) {
  ui.centre(
    [],
    ui.cluster(
      [],
      list.map(
        model.space_delimited_char_list_with_indexes,
        fn(word: List(#(String, Int, Int))) { show_word(model, word) },
      ),
    ),
  )
}

fn show_word(model: Model, word: List(#(String, Int, Int))) -> Element(Msg) {
  ui.cluster(
    [],
    list.append(
      list.map(word, fn(char: #(String, Int, Int)) { show_char(model, char) }),
      [show_space()],
    ),
  )
}

fn show_char(model: Model, char: #(String, Int, Int)) -> Element(Msg) {
  let index = char.2
  let background_color = case model.selected_char == char.0 {
    True -> "yellow"
    False -> "none"
  }

  case is_letter(char.0) {
    True ->
      html.div(
        [
          attribute.style([
            #("background-color", "lightgray"),
            #("margin-left", "-.9em"),
          ]),
        ],
        [
          ui.field(
            [],
            [],
            ui.input([
              attribute.autocomplete("off"),
              attribute.id(index |> int.to_string()),
              attribute.value(model.guess |> get_item_at_index(index)),
              event.on_input(fn(key: String) {
                msg.UserGuessedCharacter(key, index)
              }),
              event.on_keydown(fn(key: String) {
                msg.UserPressedKey(key, index)
              }),
              event.on_focus(msg.UserFocusedCharacter(char.0)),
              attribute.style([
                #("background-color", background_color),
                #("font-size", ".9em"),
                #("width", "2.5em"),
                #("text-align", "center"),
                #("height", "2em"),
              ]),
            ]),
            [show_char_clue(model, char)],
          ),
        ],
      )

    False ->
      html.span(
        [attribute.style([#("margin-top", "auto"), #("height", "100%")])],
        [element.text(char.0)],
      )
  }
}

fn show_char_clue(model: Model, char: #(String, Int, Int)) -> Element(Msg) {
  html.div(
    [
      attribute.style([
        #("display", "flex"),
        #("flex-direction", "column"),
        #("align-items", "center"),
        #("margin-right", "auto"),
        #("margin-left", "auto"),
      ]),
    ],
    [
      html.p(
        [
          attribute.style([
            #("color", "black"),
            #("margin-bottom", "-.3em"),
            #("font-size", ".75em"),
          ]),
        ],
        [
          element.text(
            model.shuffled_alphabet
            |> list.key_find(char.0)
            |> result.unwrap("")
            |> string.uppercase(),
          ),
        ],
      ),
      html.p([attribute.style([#("color", "black"), #("font-size", ".6em")])], [
        element.text(char.1 |> int.to_string()),
      ]),
    ],
  )
}

fn show_space() -> Element(Msg) {
  html.span([attribute.style([#("padding-left", "1em")])], [element.text(" ")])
}

fn show_buttons(model: Model) -> Element(Msg) {
  let hint_button_text = case model.hints < 5 {
    True -> "hint (])"
    False -> "no more"
  }

  html.div(
    [attribute.style([#("border", "1px solid red"), #("width", "80%")])],
    [
      ui.button([event.on_click(msg.UserClickedSubmit)], [
        element.text("guess (enter)"),
      ]),
      ui.button(
        [
          attribute.disabled(model.hints > 5),
          event.on_click(msg.UserRequestedHint),
        ],
        [element.text(hint_button_text)],
      ),
    ],
  )
}
