open Core.Std
open Async.Std

type result = {request_id:String.t} with sexp


val exec: Sqs_system.t -> Uri.t -> (Sqs_system.t * result, Exn.t) Deferred.Result.t
