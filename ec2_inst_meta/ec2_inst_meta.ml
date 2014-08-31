open Core.Std
open Async.Std

type error_code =
  | Unavailable_region
  | Unavailable_role with sexp

exception Err of error_code * String.t  with sexp

let role_url = "http://169.254.169.254/latest/meta-data/iam/security-credentials/"

let availability_zone =
  Uri.of_string
    "http://169.254.169.254/latest/meta-data/placement/availability-zone"

let get_availability_zone () =
  (* The zone is the region name + a one character zone idenifier. We
  mainly just split off that zoneidentifier. This will cause problems
  if there are ever more than 26 zones and AWS starts using more
  letters. However, when that happens we can switch to regexp. *)
  let open Deferred.Monad_infix in
  Cohttp_async.Client.get availability_zone
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

let make_role_endpoint role_name =
  Uri.of_string @@ role_url ^ role_name

let get_role role_name =
  let open Deferred.Monad_infix in
  let endpoint = make_role_endpoint role_name in
  Cohttp_async.Client.get endpoint
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
