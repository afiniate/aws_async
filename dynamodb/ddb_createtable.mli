open Core.Std
open Async.Std

val exec: Ddb_system.t -> Ddb_createtable_t.table ->
          (Ddb_system.t * Ddb_createtable_t.result, Exn.t) Deferred.Result.t
