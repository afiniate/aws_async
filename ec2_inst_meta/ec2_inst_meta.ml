open Core.Std
open Async.Std

type error_code =
  | Unavailable_region
  | Unavailable_role
  | Unavailable_user_data with sexp

exception Err of error_code * String.t  with sexp

let uri_of_path path =
  let base_url = "http://169.254.169.254/latest" in
  Uri.of_string (base_url ^ path)

let get_availability_zone () =
  (* The zone is the region name + a one character zone idenifier. We
  mainly just split off that zoneidentifier. This will cause problems
  if there are ever more than 26 zones and AWS starts using more
  letters. However, when that happens we can switch to regexp. *)
  let open Deferred.Monad_infix in
  let path = "/meta-data/placement/availability-zone" in
  Cohttp_async.Client.get (uri_of_path path)
  >>= fun (resp, body) ->
  Cohttp_async.Body.to_string body
  >>= fun str_body ->
  let status = Cohttp.Response.status resp in
  if `OK = status then
    return @@ Ok str_body
  else
    return @@ Error (Err
                       (Unavailable_region,
                        (Sexp.to_string
                           (Cohttp.Code.sexp_of_status_code status))))

let get_region () =
  let open Deferred.Result.Monad_infix in
  let parse_region_from_zone zone =
    String.slice zone 0 @@ (String.length zone) - 1 in
  get_availability_zone ()
  >>= fun av_zone ->
  return @@ Ok (parse_region_from_zone av_zone)

let get_role role_name =
  let open Deferred.Monad_infix in
  let path = "/meta-data/iam/security-credentials/" ^ role_name in
  Cohttp_async.Client.get (uri_of_path path)
  >>= fun (resp, body) ->
  Cohttp_async.Body.to_string body
  >>= fun str_body ->
  let status = Cohttp.Response.status resp in
  if `OK = status then
    return @@ Ok (Ec2im_iam_role_j.desc_of_string str_body)
  else
    return @@ Error (Err
                       (Unavailable_role,
                        (Sexp.to_string
                           (Cohttp.Code.sexp_of_status_code status))))

let get_user_data () =
  let open Deferred.Monad_infix in
  let path = "/user-data" in
  Cohttp_async.Client.get (uri_of_path path)
  >>= fun (resp, body) ->
  let status = Cohttp.Response.status resp in
  Cohttp_async.Body.to_string body
  >>= fun response ->
  if `OK = status then
    return @@ Ok response
  else
    return @@ Error (Err
                      (Unavailable_user_data,
                       (Sexp.to_string
                          (Cohttp.Code.sexp_of_status_code status))))
