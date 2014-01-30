open Core.Std
open Async.Std

type t

type key_value = Dynamodb_getitem_t.key_value = {
                 b: string option;
                 bs: string list option;
                 s: string option;
                 ss: string list option;
                 n: string option;
                 ns: string list option
               }

type index_capacity_unit = Dynamodb_getitem_t.index_capacity_unit =
                             { capacity_units: float }

type index_capacity_units = Dynamodb_getitem_t.index_capacity_units

type consumed_capacity = Dynamodb_getitem_t.consumed_capacity = {
                         capacity_units: float;
                         global_secondary_indexes: index_capacity_units;
                         local_secondary_indexes: index_capacity_units;
                         table_capacity: index_capacity_units;
                         table_name: string
                       }

type result = Dynamodb_getitem_t.result = {
              consumed_capacity: consumed_capacity option;
              item: (string * key_value) list
            }


type return_consumed_capacity = Dynamodb_getitem_t.return_consumed_capacity

type query =
  | Binary of String.t
  | BinarySet of String.t List.t
  | Int of Int.t
  | IntSet of Int.t List.t
  | Float of Float.t
  | FloatSet of Float.t List.t
  | Number of String.t
  | NumberSet of String.t List.t
  | String of String.t
  | StringSet of String.t List.t

val make_attribute_name: String.t -> String.t Or_error.t

val get_item: t -> ?attributes:String.t List.t ->
              ?consistent_read:Bool.t ->
              ?return_consumed_capacity:return_consumed_capacity ->
              String.t ->
              (String.t * query) List.t ->
              (Cohttp.Response.t * Dynamodb_getitem_j.result) Deferred.Or_error.t

val create: ?url:String.t -> String.t -> String.t -> String.t -> t
