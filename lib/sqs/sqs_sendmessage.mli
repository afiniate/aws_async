open Core.Std
open Async.Std

type result = {message_md5:String.t;
               message_id:String.t;
               request_id:String.t} with sexp


val exec: Sqs_system.t ->
  ?delay_seconds:Int.t ->
  queue_url:Uri.t ->
  String.t -> (Sqs_system.t * result, Exn.t) Deferred.Result.t

val name_exec: Sqs_system.t ->
  ?delay_seconds:Int.t ->
  queue_name:String.t ->
  String.t -> (Sqs_system.t * result, Exn.t) Deferred.Result.t
