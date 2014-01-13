type headers = (string * string) list

val post: Auth.t -> string -> headers -> string -> Uri.t ->
          (Cohttp.Response.t * string Async.Std.Pipe.Reader.t) Async.Std.Deferred.t
