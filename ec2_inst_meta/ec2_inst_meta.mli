open Core.Std
open Async.Std

(**
 * This module provides access to the instance metadata of an ec2 instance.
*)

val get_availability_zone: Unit.t -> (String.t, Exn.t) Deferred.Result.t
(** Get the availability zone from the instance metadata *)

val get_region: Unit.t -> (String.t, Exn.t) Deferred.Result.t
(** Get the region from the instance metadata *)

val get_role: string -> (Ec2im_iam_role_t.desc, Exn.t) Deferred.Result.t
(** Get the region from the instance metadata *)

val get_user_data: Unit.t -> (String.t, Exn.t) Deferred.Result.t
(** Returns the user data for the instance (if there is any) *)
