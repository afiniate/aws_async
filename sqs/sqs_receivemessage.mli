open Core.Std
open Async.Std

type return_attribute =
  | All
  | Approximate_first_receive_timestamp
  | Approximate_receive_count
  | Sender_id
  | Sent_timestamp

type attribute =
  | Approximate_first_receive_timestamp of Time.t
  | Approximate_receive_count of Int.t
  | Sender_id of String.t
  | Sent_timestamp of Time.t with sexp

type receipt_handle

type message = {md5:String.t;
                id:String.t;
                receipt_handle:receipt_handle;
                body:String.t;
                attributes:attribute List.t} with sexp

type result = {messages: message List.t;
               request_id:String.t} with sexp

val string_of_receipt_handle: receipt_handle -> String.t
val receipt_handle_of_string: String.t -> receipt_handle

val exec: Sqs_system.t ->
  ?return_attributes:return_attribute List.t ->
  ?max_number_of_messages:Int.t ->
  ?visibility_timeout:Int.t ->
  ?wait_time_seconds:Int.t ->
  Uri.t -> (Sqs_system.t * result, Exn.t) Deferred.Result.t

val long_poll: Sqs_system.t ->
  ?return_attributes:return_attribute List.t ->
  ?max_number_of_messages:Int.t ->
  ?visibility_timeout:Int.t ->
  Uri.t -> (Sqs_system.t * result, Exn.t) Deferred.Result.t

val name_long_poll: Sqs_system.t ->
  ?return_attributes:return_attribute List.t ->
  ?max_number_of_messages:Int.t ->
  ?visibility_timeout:Int.t ->
  String.t -> (Sqs_system.t * result, Exn.t) Deferred.Result.t

val name_exec: Sqs_system.t ->
  ?return_attributes:return_attribute List.t ->
  ?max_number_of_messages:Int.t ->
  ?visibility_timeout:Int.t ->
  ?wait_time_seconds:Int.t ->
  String.t -> (Sqs_system.t * result, Exn.t) Deferred.Result.t
