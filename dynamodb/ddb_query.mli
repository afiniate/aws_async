open Core.Std
open Async.Std

type keys = Ddb_system.attribute List.t

type condition =
  | Eq of Ddb_system.attribute_value List.t
  | Le of Ddb_system.attribute_value List.t
  | Lt of Ddb_system.attribute_value List.t
  | Ge of Ddb_system.attribute_value List.t
  | Gt of Ddb_system.attribute_value List.t
  | Begins_with of Ddb_system.attribute_value List.t
  | Between of Ddb_system.attribute_value List.t

type query = (String.t * condition) List.t

val exec: Ddb_system.t ->
          ?attributes: Ddb_query_t.attribute_name List.t ->
          ?consistent_read: Bool.t ->
          ?exclusive_start_key: keys ->
          ?index_name: String.t ->
          ?query: query ->
          ?limit: Int.t ->
          ?return_consumed_capacity: Ddb_query_t.return_consumed_capacity ->
          ?scan_index_forward: Bool.t ->
          ?select: Ddb_query_t.select ->
          String.t ->
          (Ddb_system.t * Ddb_query_t.result, Exn.t) Deferred.Result.t
