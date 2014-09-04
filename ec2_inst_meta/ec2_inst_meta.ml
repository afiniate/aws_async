open Core.Std
open Async.Std

type error_code =
  | Unavailable_region
  | Unavailable_role
  | Unavailable_user_data with sexp

exception Err of error_code * String.t  with sexp

let make_err error_code status_code =
  Err (error_code,
       (Sexp.to_string (Cohttp.Code.sexp_of_status_code status_code)))

let process_result error_code (resp, body) =
  let status_code = Cohttp.Response.status resp in
  if `OK = status_code then
    Cohttp_async.Body.to_string body >>| fun s -> Ok s
  else
    return @@ Error (make_err error_code status_code)

let fetch_metadata error_cb path =
  let base_url = "http://169.254.169.254/latest" in
  let uri = Uri.of_string (base_url ^ path) in
  Cohttp_async.Client.get uri
  >>= process_result error_cb

(* -------------------------------------------------------------------- *)
(* Public API                                                           *)
(* -------------------------------------------------------------------- *)
let get_availability_zone () =
  let path = "/meta-data/placement/availability-zone" in
  fetch_metadata Unavailable_region path

let get_region () =
  (* The zone is the region name + a one character zone idenifier. We
     mainly just split off that zoneidentifier. This will cause problems
     if there are ever more than 26 zones and AWS starts using more
     letters. However, when that happens we can switch to regexp. *)
  let parse_region_from_zone zone =
    String.slice zone 0 @@ (String.length zone) - 1 in
  get_availability_zone () >>|? parse_region_from_zone

let get_role role_name =
  let path = "/meta-data/iam/security-credentials/" ^ role_name in
  fetch_metadata Unavailable_role path >>|? Ec2im_iam_role_j.desc_of_string

let get_user_data () =
  fetch_metadata Unavailable_user_data "/user-data"
