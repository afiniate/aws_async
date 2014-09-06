open Core.Std
open Async.Std

val exec: Ddb_system.t ->
  ?expected:Ddb_putitem_t.expected ->
  ?return_consumed_capacity:Ddb_putitem_t.return_consumed_capacity ->
  ?return_collection_metrics:Ddb_putitem_t.return_collection_metrics ->
  ?return_values:Ddb_putitem_t.return_values ->
  String.t ->
  Ddb_system.item ->
  (Ddb_system.t * Ddb_putitem_t.result, Exn.t) Deferred.Result.t
