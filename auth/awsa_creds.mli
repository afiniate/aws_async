open Core.Std
open Async.Std

val resolve: ?region:String.t -> Awsa_base.t ->
  (Awsa_base.t * Awsa_base.creds, Exn.t) Deferred.Result.t
