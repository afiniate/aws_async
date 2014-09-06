open Core.Std
open Async.Std

val exec: Ddb_system.t -> ?exclusive_start_table_name:String.t ->
  ?limit:Int.t -> Unit.t ->
  (Ddb_system.t * Ddb_listtables_t.result, Exn.t) Deferred.Result.t
