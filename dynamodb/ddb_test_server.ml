(* Functions to manage the Dynamodb test server *)

open Core.Std
open Async.Std

let manage cmd =
  Async_shell.run_full "/opt/dynamodb/bin/dynamodb-test-server" [cmd]

let ignore_output _ = return ()

(* TODO: wait until the socket is up instead of 5 seconds *)
let start () =
  manage "restart"
  >>= fun _ -> after (Time.Span.of_sec 5.0)
  >>= ignore_output

let stop () =
  manage "stop"
  >>= ignore_output

let is_running () =
  manage "status"
  >>| String.substr_index ~pattern:"is running"
  >>| function
  | Some _ -> true
  | None -> false

let with_test_server thunk =
  start ()
  >>= fun _ -> thunk ()
  >>= fun result -> stop ()
  >>= fun _ -> return result
