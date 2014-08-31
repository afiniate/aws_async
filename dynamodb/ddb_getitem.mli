open Core.Std
open Async.Std

type keys = Ddb_system.attribute List.t

val exec: Ddb_system.t -> ?attributes:Ddb_getitem_t.attribute_name List.t ->
          ?consistent_read:Bool.t ->
          ?return_consumed_capacity:Ddb_getitem_t.return_consumed_capacity ->
          String.t ->
          keys ->
          (Ddb_system.t * Ddb_getitem_t.result, Exn.t) Deferred.Result.t
