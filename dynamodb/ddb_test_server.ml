(* Functions to manage the Dynamodb test server *)

open Core.Std
open Async.Std

exception Timeout

let manage cmd =
  Async_shell.run_full "/opt/dynamodb/bin/dynamodb-test-server" [cmd]

let ignore_output _ = return ()

(* Parameters for the test local dynamodb server, it doesn't check
   any authorisation values, so we just make them obviously made up *)
let test_url = "http://localhost:53321"
let test_access_id = "fake access id"
let test_secret_key = "fake secret key"
let test_region = "fake region"

let rec repeat_until wait_period condition =
  condition ()
  >>= function
  | true -> return ()
  | false ->
    after wait_period
    >>= fun () -> repeat_until wait_period condition

let repeat_until_with_timeout timeout wait_period condition =
  with_timeout timeout (repeat_until wait_period condition)
  >>| function
  | `Result x -> Ok x
  | `Timeout -> Error Timeout

(* Send an arbitrary command to verify the server is up and running *)
let ping () =
  let dynamodb = Aws.Dynamodb.t_of_credentials
      ~url:test_url test_access_id test_secret_key test_region in
  try_with @@ Aws.Dynamodb.Listtables.exec ~limit:1 dynamodb
  >>| function
  | Ok _ -> true
  | Error _ -> false

let default_wait_period = Time.Span.of_sec 0.1

let wait_for_ping timeout =
  repeat_until_with_timeout timeout default_wait_period ping

(* waiting until status running is not enough as the server doesn't respond to
   queries immediately, so we wait until it is pinging back *)
let start () =
  manage "restart"
  >>= fun _ -> wait_for_ping (Time.Span.of_int_sec 5)
  >>= ignore_output

let is_running () =
  manage "status"
  >>| String.substr_index ~pattern:"is running"
  >>| function
  | Some _ -> true
  | None -> false

let wait_until_stopped timeout =
  repeat_until_with_timeout timeout default_wait_period
    (fun () -> is_running ()
      >>| fun x -> not x)

let stop () =
  manage "stop"
  >>= fun _ -> wait_until_stopped (Time.Span.of_int_sec 1)
  >>= ignore_output

let with_test_server thunk =
  start ()
  >>= fun _ -> thunk ()
  >>= fun result -> stop ()
  >>= fun _ -> return result
