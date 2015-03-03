open Core.Std
open Async.Std

let rec execute_async_tests tests =
  match tests with
  | [] -> return ();
  | (name, t)::ts ->
    let open Deferred.Monad_infix in
    t ()
    >>= (function
        | Ok () ->
          printf "%s...PASSED\n" name;
          execute_async_tests ts
        | Error ex ->
          raise ex)

let () =
  print_string "Starting async tests ...\n";
  print_newline ();
  ignore @@ (execute_async_tests Aws_auth_tests.tests
             >>| fun _ -> shutdown 0);
  never_returns (Scheduler.go ());
