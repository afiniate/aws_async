open Core.Std
open Async.Std

val url : String.t
(** The local DB server URL *)

val access_id : String.t
(** The Access ID for the local DB server *)

val secret_key : String.t
(** The Secret Key for the local DB server *)

val region : String.t
(** A fake region to use to access the local DB Server *)

val start : Unit.t -> Unit.t Deferred.t
(** Ensures the test db server is started and responding to queries *)

val stop : Unit.t -> Unit.t Deferred.t
(** Ensures the test db server is stopped *)

val is_running : Unit.t -> bool Deferred.t
(** Whether the test db server is running *)

val with_test_server : (Unit.t -> 'a Deferred.t) -> 'a Deferred.t
(** Runs a deferred thunk with the test server started, stopping it afterwards.
    The return value is the result of evaluating the thunk *)
