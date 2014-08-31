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

exception Error of error_code * String.t  with sexp

type attribute_name = String.t
type attribute_value = Ddb_base_t.attribute
type attribute = attribute_name * Ddb_base_t.attribute
type item = attribute List.t

let service_name = "dynamodb"
let api_version = "DynamoDB_20120810"

let binary b =
  {Ddb_base_t.b = Some b; bs = None; s = None; ss = None; n = None; ns = None}

let binary_set bs =
  {Ddb_base_t.b = None; bs = Some bs; s = None; ss = None; n = None; ns = None}

let string s =
  {Ddb_base_t.b = None; bs = None; s = Some s;
   ss = None; n = None; ns = None}

let string_set ss =
  {Ddb_base_t.b = None; bs = None; s = None;
   ss = Some ss; n = None; ns = None}

let float f =
  {Ddb_base_t.b = None; bs = None; s = None; ss = None;
   n = Some (Float.to_string f); ns = None}

let float_set fs =
  {Ddb_base_t.b = None; bs = None; s = None; ss = None; n = None;
   ns = Some (List.map ~f:(fun x -> Float.to_string x) fs)}

let int i =
  {Ddb_base_t.b = None; bs = None; s = None; ss = None;
   n = Some (string_of_int i); ns = None}

let int_set is =
  {Ddb_base_t.b = None; bs = None; s = None; ss = None; n = None;
   ns = Some (List.map ~f:(fun x -> string_of_int x) is)}

let invalid_field field =
  Core.Std.Error (Error (Invalid_field field,
                         "Invalid field: " ^ field))

let try_with field fn =
    try
      Ok (fn ())
    with
      _ -> Core.Std.Error (Error (Invalid_field field,
                                  "Conversion error: " ^ field))

let get_string_set field item =
  match List.Assoc.find item field with
  | Some {Ddb_base_t.ss=Some s} -> Ok s
  | Some {ss=None} ->
     invalid_field field
  | None ->
     invalid_field field

let get_string field item =
  match List.Assoc.find item field with
  | Some {Ddb_base_t.s=Some s} -> Ok s
  | Some {s=None} ->
     invalid_field field
  | None ->
     invalid_field field

let get_float_set field item =
  match List.Assoc.find item field with
  | Some {Ddb_base_t.ns=Some ns} ->
     try_with field (fun () ->
                     List.map
                       ~f:(fun x -> Float.of_string x) ns)
  | Some {ns=None} ->
     invalid_field field
  | None ->
     invalid_field field

let get_float field item =
  match List.Assoc.find item field with
  | Some {Ddb_base_t.n=Some n} ->
     try_with field (fun () ->
                     Float.of_string n)
  | Some {n=None} ->
     invalid_field field
  | None ->
     invalid_field field

let get_int_set field item =
  match List.Assoc.find item field with
  | Some {Ddb_base_t.ns=Some ns} ->
     try_with field (fun () ->
                     List.map
                       ~f:(fun x -> Int.of_string x) ns)
  | Some {ns=None} ->
     invalid_field field
  | None ->
     invalid_field field

let get_int field item =
  match List.Assoc.find item field with
  | Some {Ddb_base_t.n=Some n} ->
     try_with field (fun () -> Int.of_string n)
  | Some {n=None} ->
     invalid_field field
  | None ->
     invalid_field field


let get_binary_set field item =
  match List.Assoc.find item field with
  | Some {Ddb_base_t.bs=Some bin} -> Ok bin
  | Some {bs=None} ->
     invalid_field field
  | None ->
     invalid_field field

let get_binary field item =
  match List.Assoc.find item field with
  | Some {Ddb_base_t.b=Some bin} -> Ok bin
  | Some {b=None} ->
     invalid_field field
  | None ->
     invalid_field field

let make_url region = function
  | None -> Uri.of_string ("http://dynamodb." ^
                             region ^ ".amazonaws.com")
  | Some new_url -> Uri.of_string new_url

let t_of_credentials ?url access_id secret_key region =
  let dyn_url = make_url region url in
  {auth = Aws_auth.t_of_credentials access_id secret_key region;
   region = region;
   url = dyn_url}

let t_of_role ?url role =
  let open Deferred.Result.Monad_infix in
  Ec2_inst_meta.get_region ()
  >>= fun region ->
  Aws_auth.t_of_role ~region role
  >>= fun auth ->
  let dyn_url = make_url region url in
  return @@ Ok {auth = auth;
                region = region;
                url = dyn_url}
