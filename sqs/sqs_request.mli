open Core.Std
open Async.Std

val get: Aws_auth.t -> String.t -> Uri.t ->
          (Aws_auth.t * String.t, Exn.t) Deferred.Result.t
