open Core.Std
open Async.Std

type headers = (string * string) list

let post auth service headers body url =
  let body_len = String.length body in
  let headers' = ("content-type", "application/x-amz-json-1.0")::
                   ("content-length", string_of_int body_len)::headers in
  let authed_headers = Cohttp.Header.of_list
                         (Auth.v4_authorize auth service "POST" url
                                            headers' body) in
  let async_body = Pipe.of_list [body] in
  Cohttp_async.Client.post ~headers:authed_headers ~body:async_body url
