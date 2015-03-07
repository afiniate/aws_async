open Core.Std
open Async.Std

type t = {auth: Aws_auth.t;
          region: String.t;
          url: Uri.t}

type service_error = {t:String.t;
                      code: String.t;
                      message: String.t;
                      detail: String.t;
                      request_id: String.t} with sexp

type error_code =
  | Service_error of service_error
  | Parse_error
  | Unexpected_xml_element of String.t
  | Unexpected_xml_end_element
  | Unexpected_dtd
  | Unexpected_xml_data_element of String.t
  | Invalid_attribute of String.t * String.t with sexp

exception Error of error_code * String.t  with sexp

val service: String.t

val t_of_credentials: ?url:String.t -> String.t -> String.t -> String.t -> t
val t_of_role: ?url:String.t -> String.t -> (t, Exn.t) Deferred.Result.t
