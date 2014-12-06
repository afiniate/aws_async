open Core.Std
open Async.Std

let restore_db = function
  | false -> Ddb_test_server.stop ()
  | true -> Ddb_test_server.start ()

let run_ddb_tests tests =
  Ddb_test_server.is_running ()
  >>= fun was_running -> tests ()
  >>= fun result -> restore_db was_running
  >>= fun _ -> return result

let format_error command_run expected =
  sprintf
    "Expected is_running to be %s after %s"
    (string_of_bool expected) command_run

let assert_state name expected =
  Ddb_test_server.is_running ()
  >>| fun gotten ->
  if gotten = expected
  then Ok ()
  else Error (format_error name expected)

let test_stopped () =
  Ddb_test_server.stop ()
  >>= fun _ -> assert_state "stopped" false

let test_started () =
  Ddb_test_server.stop ()
  >>= fun _ -> assert_state "stopped" false

let test_with_test_server running =
  restore_db running
  >>= fun _ ->
  Ddb_test_server.with_test_server
    (fun () -> assert_state "with_test_server" true)

  (* TODO fix stop so that it waits until the state is actually stopped *)
  >>= fun result_from_within -> after (Time.Span.of_sec 0.5)
  >>= fun _ -> assert_state "with_test_server cleanup" false

  >>|? fun _ -> result_from_within

let tests () =
  test_stopped ()
  >>=? test_started
  >>=? fun _ -> test_with_test_server true
  >>=? fun _ -> test_with_test_server false

let test_start_stop () =
  return @@ Ok ()

let test () =
  run_ddb_tests tests
  >>= function
  | Error reason -> printf "tests failed!:\n\n%s\n\n" reason;
    exit 1
  | Ok _ -> print_string "test passed!\n";
    return ()

let _ =
  Command.async ~summary:"System tests for Aws_inst_meta"
    Command.Spec.empty test
  |> Command.run
