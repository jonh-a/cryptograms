import data/model.{type Model, Model, SolutionStatistics}
import data/msg
import gleam/dynamic
import gleam/json.{type Json, bool, int, object, string}
import lustre_http.{type Expect, expect_json, post}

pub fn format_solve_data_to_json(model: Model) -> Json {
  object([
    #(
      "quote",
      object([#("fakeapi_item", bool(True)), #("type", string("name"))]),
    ),
    #(
      "average_solve_time",
      object([
        #("fakeapi_item", bool(True)),
        #("type", string("number")),
        #("min", int(25)),
        #("max", int(300)),
      ]),
    ),
  ])
}

pub fn submit_solve_statistics(model: Model) {
  let url = "https://fake-api.usingthe.computer/data"
  let body = format_solve_data_to_json(model)
  let decoder =
    dynamic.decode2(
      SolutionStatistics,
      dynamic.field("quote", dynamic.string),
      dynamic.field("average_solve_time", dynamic.int),
    )

  post(url, body, expect_json(decoder, msg.BackendProvidedResponse))
}
