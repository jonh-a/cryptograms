import data/model.{type Model, Model}
import data/msg.{type Msg}
import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import update/handlers
import view/cryptogram.{show_cryptogram}
import view/solved.{show_solved}

pub fn main() {
  let app = lustre.application(handlers.init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    msg.UserClickedSubmit -> handlers.handle_button_click(model)
    msg.UserGuessedCharacter(value, index) -> #(
      handlers.handle_user_guessed_character(model, value, index),
      effect.none(),
    )
    msg.UserFocusedCharacter(char) -> #(
      handlers.handle_user_focused_character(model, char),
      effect.none(),
    )
    msg.UserClickedPlayAnother -> handlers.handle_user_clicked_play_another()
    msg.UserRequestedHint -> #(
      handlers.handle_user_requested_hint(model),
      effect.none(),
    )
    msg.UserPressedKey(key, index) ->
      handlers.handle_user_pressed_key(model, key, index)
    msg.BackendProvidedResponse(result) -> #(
      handlers.handle_backend_provided_response(model, result),
      effect.none(),
    )
  }
}

fn view(model: Model) -> Element(Msg) {
  case model.solved {
    True -> show_solved(model)
    False -> show_cryptogram(model)
  }
}
