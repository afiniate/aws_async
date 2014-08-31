open Core.Std
open Async.Std

(**
 * The type carrying all the default information used by authorize
 *)
type t
type headers = Awsa_headers.t

(**
 * authorize a request using the aws authorization scheme v4.
 *
 * @param sys The base authorization information
 * @param region The region to use, if none is provided then the default
 *               region from the base authorization info is used
 * @param service The service that this authorization information will be used
 *                against
 * @param httpMethod The http method being used
 * @param uri The uri that is being authed
 * @param headers The list of headers that will be used
 * @param body The body information that will be used, an empty string if non
 * @return A list of authorized headers that should be provide to the aws service
 *)
val v4_authorize: t -> ?region:String.t -> String.t ->
                  String.t -> Uri.t -> headers -> String.t ->
                  (t * headers, Exn.t) Deferred.Result.t

(**
 * Create a new base set of defaults from credentials
 *
 * @param secret_access_key the aws secret access key
 * @param access_key_id the amazon access key id
 * @param default_region the default region to use (can be overridden
 *        on a call by call basis)
 *)
val t_of_credentials: String.t -> String.t -> String.t -> t

(**
 * Create a new base set of defaults from from a role name. This must
 * be done on an ec2 host or a host that supports IAM roles
 *
 * @param role_name The name of the role
 *)
val t_of_role: ?region:String.t -> String.t -> (t, Exn.t) Deferred.Result.t
