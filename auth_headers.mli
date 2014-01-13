(**
 * Process a set of headers in the manner indicated by aws for all other
 * requests
 *)
type header = (string * string)
type t = header list

val process: Uri.t -> t -> (Core.Std.Unix.tm * t * t)
val print: t -> unit
