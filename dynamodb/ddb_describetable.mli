open Core.Std
open Async.Std

val exec: Ddb_system.t -> String.t ->
          (Ddb_system.t * Ddb_describetable_t.result, Exn.t) Deferred.Result.t
