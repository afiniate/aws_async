open Core.Std
open Async.Std

let test () =
  Ec2_inst_meta_tests.unit ()
  >>= function
  | Error _ -> print_string "tests failed!\n";
    exit 1
  | Ok _ -> print_string "test passed!\n";
    return ()

let _ =
  Command.async ~summary:"Unit tests for Aws_inst_meta"
    Command.Spec.empty test
  |> Command.run
