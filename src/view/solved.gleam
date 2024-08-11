import data/model.{type Model, Model}
import data/msg.{type Msg}
import gleam/int
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import lustre/ui

pub fn show_solved(model: Model) -> Element(Msg) {
  let solved_time = model.solve_time - model.start_time
  ui.centre(
    [],
    html.div([], [
      html.h1([], [element.text(model.answer)]),
      html.h2([], [
        element.text("solved in " <> int.to_string(solved_time) <> " seconds"),
      ]),
      ui.button([event.on_click(msg.UserClickedPlayAnother)], [
        element.text("play another"),
      ]),
    ]),
  )
}
