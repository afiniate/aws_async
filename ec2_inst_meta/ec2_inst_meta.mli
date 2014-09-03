open Core.Std
open Async.Std

(** Provides access to instance metadata when run in an ec2 instance *)

module type Fetcher = sig
  val fetch: String.t -> (String.t, Exn.t) Deferred.Result.t
  (** Fetch the metadata referred by the argument

      The argument is a path to the required metadata, excluding the root URI
      for the latest version. For example, the path "/iam/info". will be
      translated into a GET to "http://169.254.169.254/latest/iam/info" by
      the production Fetcher *)
end

module type Api = sig
  val get_availability_zone : Unit.t -> (String.t, Exn.t) Deferred.Result.t
  (** Return the availability zone of the running instance *)

  val get_region : Unit.t -> (String.t, Exn.t) Deferred.Result.t
  (** Return the region of the running instance *)

  val get_role : String.t -> (Ec2im_iam_role_t.desc, Exn.t) Deferred.Result.t
  (** Return the role description of the running instance *)

  val get_user_data : Unit.t -> (String.t, Exn.t) Deferred.Result.t
  (** Return the user data of the running instance, if there are any *)
end

(** This functor delegates all side effects to the Fetcher so that we can unit
    test this module in isolation. It has the same API as the main module, but
    you must provide an alternative fetcher that simulates the HTTP interface
    available in EC2 instances *)
module Make (Fetcher : Fetcher) : Api

(* Default Api using the production fetcher *)
include Api
