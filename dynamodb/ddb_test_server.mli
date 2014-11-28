open Core.Std
open Async.Std

val start : Unit.t -> Unit.t Deferred.t
(** Ensures the test db server is started *)

val stop : Unit.t -> Unit.t Deferred.t
(** Ensures the test db server is stopped *)

val is_running : Unit.t -> bool Deferred.t
(** Whether the test db server is running *)

val with_test_server : (Unit.t -> 'a Deferred.t) -> 'a Deferred.t
(** Runs a deferred thunk with the test server started, stopping it afterwards.
    The return value is the result of evaluating the thunk *)
