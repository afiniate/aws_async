open Core.Std

type headers = (string * string) list

val sexp_of_response: (Cohttp.Response.t * string) -> Sexp.t

val post: Auth.t -> string -> headers -> string -> Uri.t ->
          (Cohttp.Response.t * string Async.Std.Pipe.Reader.t) Async.Std.Deferred.t
