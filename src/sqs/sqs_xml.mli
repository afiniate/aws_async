open Core.Std

type peek =
  | Start of String.t
  | End

val do_if_tag: Xmlm.input ->
  name:String.t ->
  (Xmlm.input -> ('a, Exn.t) Result.t) ->
  (Xmlm.input -> ('a, Exn.t) Result.t) -> ('a, Exn.t) Result.t

val peek_type: Xmlm.input -> (Xmlm.input * peek, Exn.t) Result.t
val extract_body: Xmlm.input -> (Xmlm.input * String.t, Exn.t) Result.t
val extract_tag_body: Xmlm.input -> name:String.t -> (Xmlm.input * String.t, Exn.t) Result.t
val expect_tag: Xmlm.input -> name:String.t -> (Xmlm.input, Exn.t) Result.t
val expect_dtd: Xmlm.input -> (Xmlm.input, Exn.t) Result.t
val expect_end: Xmlm.input -> (Xmlm.input, Exn.t) Result.t
val expect_data: Xmlm.input -> (Xmlm.input, Exn.t) Result.t
