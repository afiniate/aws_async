open Core.Std
open Async.Std

type role_desc = Ec2im_iam_role_t.desc

module type Api = sig
  val get_availability_zone : Unit.t -> (String.t, Exn.t) Deferred.Result.t
  val get_region : Unit.t -> (String.t, Exn.t) Deferred.Result.t
  val get_role : String.t -> (role_desc, Exn.t) Deferred.Result.t
  val get_user_data : Unit.t -> (String.t, Exn.t) Deferred.Result.t
end

module type Fetcher = sig
  val fetch: String.t -> (String.t, Exn.t) Deferred.Result.t
end

module Make (Fetcher : Fetcher) : Api = struct
  let get_availability_zone () =
    Fetcher.fetch "/meta-data/placement/availability-zone"

  let get_region () =
    (* The zone is the region name + a one character zone idenifier. We
       mainly just split off that zoneidentifier. This will cause problems
       if there are ever more than 26 zones and AWS starts using more
       letters. However, when that happens we can switch to regexp. *)
    let parse_region_from_zone zone =
      String.slice zone 0 @@ (String.length zone) - 1 in
    get_availability_zone ()
    >>|? parse_region_from_zone

  let get_role role_name =
    let path = "/meta-data/iam/security-credentials/" ^ role_name in
    Fetcher.fetch path
    >>|? Ec2im_iam_role_j.desc_of_string

  let get_user_data () =
    Fetcher.fetch "/user-data"
end

(* Production Fetcher *)

module Prod_fetcher : Fetcher = struct
  (* The payload is the HTTP error code and the Uri that we tried to fetch *)
  exception Cannot_fetch_metadata of Cohttp.Code.status_code * Uri.t with sexp

  let process_result uri (resp, body) =
    let status_code = Cohttp.Response.status resp in
    if `OK = status_code then
      Cohttp_async.Body.to_string body
      >>| fun s -> Ok s
    else
      return @@ Error (Cannot_fetch_metadata (status_code, uri))

  let fetch path =
    let base_url = "http://169.254.169.254/latest" in
    let uri = Uri.of_string (base_url ^ path) in
    Cohttp_async.Client.get uri
    >>= process_result uri
end

(* Production API *)

include Make(Prod_fetcher)
