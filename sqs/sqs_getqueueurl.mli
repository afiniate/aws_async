open Core.Std
open Async.Std

type result = {queue_url:Uri.t;
               request_id:String.t} with sexp

val exec: Sqs_system.t ->
          ?queue_owner_aws_account_id:String.t ->
          String.t -> (Sqs_system.t * result, Exn.t) Deferred.Result.t
