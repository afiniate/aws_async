open Core.Std
open Async.Std

type headers = (string * string) list

val parse_error: Ddb_base_t.error -> Exn.t

val try_parse: sys:Ddb_system.t -> f:(String.t -> 'a) -> (Aws_auth.t * String.t) ->
               (Ddb_system.t * 'a, Exn.t) Deferred.Result.t

val post: Aws_auth.t -> headers -> String.t -> Uri.t ->
          (Aws_auth.t * String.t, Exn.t) Deferred.Result.t
