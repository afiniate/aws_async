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

let service = "sqs"

let make_url region url =
  match url with
  | None -> Uri.of_string ("http://sqs." ^
                             region ^ ".amazonaws.com")
  | Some new_url -> Uri.of_string new_url

let t_of_credentials ?url access_id secret_key region =
  let actual_url = make_url region url in
  {auth = Aws_auth.t_of_credentials access_id secret_key region;
   region = region;
   url = actual_url}

let t_of_role ?url role =
  let open Deferred.Result.Monad_infix in
  Ec2_inst_meta.get_region ()
  >>= fun region ->
  Aws_auth.t_of_role ~region role
  >>= fun auth ->
  let actual_url = make_url region url in
  return @@ Ok {auth = auth;
                region = region;
                url = actual_url}
