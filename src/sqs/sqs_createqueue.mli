open Core.Std
open Async.Std

type result = {queue_url:Uri.t;
               request_id:String.t} with sexp


val exec: Sqs_system.t ->
  ?delay_seconds:Int.t ->
  ?maximum_message_size:Int.t ->
  ?message_retention_period:Int.t ->
  ?policy:Sqs_policy_t.policy ->
  ?receive_message_wait_time_seconds:Int.t ->
  ?visibility_timeout:Int.t ->
  String.t -> (Sqs_system.t * result, Exn.t) Deferred.Result.t
