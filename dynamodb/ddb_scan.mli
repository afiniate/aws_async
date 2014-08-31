open Core.Std
open Async.Std

type keys = Ddb_system.attribute List.t

type condition =
  | Eq of Ddb_system.attribute_value List.t
  | Ne of Ddb_system.attribute_value List.t
  | Le of Ddb_system.attribute_value List.t
  | Lt of Ddb_system.attribute_value List.t
  | Ge of Ddb_system.attribute_value List.t
  | Gt of Ddb_system.attribute_value List.t
  | Not_null of Ddb_system.attribute_value List.t
  | Null of Ddb_system.attribute_value List.t
  | Contains of Ddb_system.attribute_value List.t
  | Not_contains of Ddb_system.attribute_value List.t
  | Begins_with of Ddb_system.attribute_value List.t
  | Between of Ddb_system.attribute_value List.t

type filter =
  | And of (String.t * condition) List.t
  | Or of (String.t * condition) List.t

val exec: Ddb_system.t ->
          ?attributes: Ddb_scan_t.attribute_name List.t ->
          ?exclusive_start_key: keys ->
          ?limit: Int.t ->
          ?return_consumed_capacity: Ddb_scan_t.return_consumed_capacity ->
          ?filter: filter ->
          ?segment: Int.t ->
          ?total_segments: Int.t ->
          ?select: Ddb_scan_t.select ->
          String.t ->
          (Ddb_system.t * Ddb_scan_t.result, Exn.t) Deferred.Result.t


val all: Ddb_system.t ->
         ?attributes: Ddb_scan_t.attribute_name List.t ->
         ?exclusive_start_key: keys ->
         ?limit: Int.t ->
         ?return_consumed_capacity: Ddb_scan_t.return_consumed_capacity ->
         ?segment: Int.t ->
         ?total_segments: Int.t ->
         ?select: Ddb_scan_t.select ->
         String.t ->
         (Ddb_system.t * Ddb_scan_t.result, Exn.t) Deferred.Result.t
