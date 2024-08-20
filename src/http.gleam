import data/model.{type Model, Model, SolutionStatistics}
import data/msg.{type Msg}
import gleam/dynamic
import gleam/json.{type Json, int, object, string}
import lustre/effect.{type Effect}
import lustre_http.{expect_json, post}
import util.{get_unix_time_now}

pub fn submit_solve_statistics(model: Model) -> Effect(Msg) {
  let url = "https://misc.usingthe.computer/cryptograms/solve"
  let body = format_solve_data_to_json(model)

  let decoder =
    dynamic.decode3(
      SolutionStatistics,
      dynamic.field("puzzle", dynamic.string),
      dynamic.field("average", dynamic.int),
      dynamic.field("time", dynamic.int),
    )

  post(url, body, expect_json(decoder, msg.BackendProvidedResponse))
}

fn format_solve_data_to_json(model: Model) -> Json {
  let solved_in = get_unix_time_now() - model.start_time
  object([#("puzzle", string(model.answer)), #("solveTime", int(solved_in))])
}
