open Core.Std
open Async.Std

type t = {auth: Aws_auth.t;
          region: String.t;
          url: Uri.t}

type error_code =
  | Access_denied
  | Conditional_check_failed
  | Incomplete_signature
  | Item_collection_size_limit_exceeded
  | Limit_exceeded
  | Missing_authentication_token
  | Provisioned_throughput_exceeded
  | Resource_in_use
  | Resource_not_found
  | Throttling
  | Unrecognized_client
  | Validation_error
  | Entity_too_large
  | Internal_failure
  | Internal_server_error
  | Invalid_action
  | Invalid_client_token_id
  | Invalid_parameter_combination
  | Invalid_parameter_value
  | Invalid_query_parameter
  | Malformed_query_string
  | Missing_action
  | Missing_parameter
  | Opt_in_required
  | Request_expired
  | Service_unavailable
  | Invalid_field of String.t
  | Invalid_error_type of String.t with sexp

exception Error of error_code * String.t with sexp

type attribute_name = String.t

type attribute_value = Ddb_base_t.attribute
type attribute = attribute_name * attribute_value
type item = attribute List.t

val service_name: string
val api_version: string


val binary: String.t -> attribute_value
val binary_set: String.t List.t -> attribute_value
val string: String.t -> attribute_value
val string_set: String.t List.t -> attribute_value
val float: Float.t -> attribute_value
val float_set: Float.t List.t -> attribute_value
val int: Int.t -> attribute_value
val int_set: Int.t List.t -> attribute_value

val get_string_set: String.t -> item ->
                    (String.t List.t, Exn.t) Result.t
val get_string: String.t -> item  -> (String.t, Exn.t) Result.t
val get_float_set: String.t -> item  -> (Float.t List.t, Exn.t) Result.t
val get_float: String.t -> item  -> (Float.t, Exn.t) Result.t
val get_int_set: String.t -> item  -> (Int.t List.t, Exn.t) Result.t
val get_int: String.t -> item  -> (Int.t, Exn.t) Result.t
val get_binary_set: String.t -> item  -> (String.t List.t, Exn.t) Result.t
val get_binary: String.t -> item  -> (String.t, Exn.t) Result.t

val t_of_credentials: ?url:String.t -> String.t -> String.t -> String.t -> t

val t_of_role: ?url:String.t -> String.t -> (t, Exn.t) Deferred.Result.t
(**
 * create a dynamodb system from an IAM role and region
 *)
