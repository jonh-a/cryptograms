import data/model.{type Model, Model}
import data/msg.{type Msg}
import gleam/int
import gleam/option.{None, Some}
import http.{submit_solve_statistics}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import lustre/ui

pub fn show_solved(model: Model) -> Element(Msg) {
  let solved_time = model.solve_time - model.start_time
  submit_solve_statistics(model)

  ui.centre(
    [event.on_keydown(fn(key: String) { msg.UserPressedKey(key, 0) })],
    html.div([], [
      html.h1([], [element.text(model.answer)]),
      html.h2([], [
        element.text("solved in " <> int.to_string(solved_time) <> " seconds"),
      ]),
      show_solution_statistics(model),
      ui.button([event.on_click(msg.UserClickedPlayAnother)], [
        element.text("play another"),
      ]),
    ]),
  )
}

fn show_solution_statistics(model: Model) -> Element(Msg) {
  html.div([], [
    case model.solution_statistics {
      Some(result) ->
        html.h2([], [
          element.text(
            "average time: " <> result.average_solve_time |> int.to_string(),
          ),
        ])
      None -> html.h2([], [])
    },
  ])
}
