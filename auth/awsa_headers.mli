open Core.Std

(**
 * Process a set of headers in the manner indicated by aws for all other
 * requests
 *)
type header = (String.t * String.t)
type t = header list

val process: Uri.t -> t -> (Unix.tm * t * t)
val print: t -> unit
