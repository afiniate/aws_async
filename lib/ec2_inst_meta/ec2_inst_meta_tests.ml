open Core.Std
open Async.Std

exception TestFailed of String.t

let test_machine_role = "devbox"

let dummy_role_desc =
  let open Ec2im_iam_role_t in
  { code = "Success"
  ; last_updated = "2014-09-20T16:33:35Z"
  ; signature_type = "AWS-HMAC"
  ; access_key_id = "XXX"
  ; secret_access_key = "XXX"
  ; token = "XXX"
  ; expiration = "2014-09-20T22:34:27Z"
  }

(* Instantiate a version of Aws_async.Ec2_inst_meta that doesn't need to run inside an
   EC2 instance *)
module Test_fetcher : Aws_async.Ec2_inst_meta.Fetcher = struct

  (* Simulate the credentials body that can be returned by AWS *)
  let credentials_json =
    let open Ec2im_iam_role_t in
    Printf.sprintf
      ("{\"Code\" : %S, "
       ^^ "\"LastUpdated\" : %S, "
       ^^ "\"Type\" : %S, "
       ^^ "\"AccessKeyId\" : %S, "
       ^^ "\"SecretAccessKey\" : %S, "
       ^^ "\"Token\" : %S, "
       ^^ "\"Expiration\" : %S}")
      dummy_role_desc.code
      dummy_role_desc.last_updated
      dummy_role_desc.signature_type
      dummy_role_desc.access_key_id
      dummy_role_desc.secret_access_key
      dummy_role_desc.token
      dummy_role_desc.expiration

  let fetch =
    let return = Deferred.Result.return in
    function
    | "/meta-data/placement/availability-zone" -> return "eu-west-1c"
    | "/meta-data/iam/security-credentials/devbox" -> return credentials_json
    | "/user-data" -> return "test user data"
    | _ -> Deferred.return @@ Error (TestFailed "this is fake for now")
end

module Test = Aws_async.Ec2_inst_meta.Make (Test_fetcher)

(* Tests *)

let match_with match_string error_string result =
  let test x = if x = match_string then
      Ok ()
    else
      Error (TestFailed (error_string ^ ": " ^ x)) in
  let open Result in
  result >>= test

(* This contains tests that are expected to behave the same whit the test
  instantiation of Ec2_inst_meta and the real production instantiation to avoid
  duplicating code in unit and system tests *)
module Make_common (Ec2_inst_meta : Aws_async.Ec2_inst_meta.Api) = struct

  let get_user_data_test () =
    Ec2_inst_meta.get_user_data ()
    >>| match_with "test user data" "get_user_data"

  let test = get_user_data_test
end

(* Unit tests using an instantiation of Ec2_inst_meta that doesn't depend on the
  environment *)
module Unit = struct
  module Common = Make_common(Test)

  let get_availability_zone_test () =
    Test.get_availability_zone ()
    >>| match_with "eu-west-1c" "get_availability_zone"

  let get_region_test () =
    Test.get_region ()
    >>| match_with "eu-west-1" "get_region"

  let get_role_test () =
    let open Ec2im_iam_role_t in
    let expected = dummy_role_desc in
    let different_role_error bad_role =
      let good_string = Ec2im_iam_role_j.string_of_desc expected in
      let bad_string = Ec2im_iam_role_j.string_of_desc bad_role in
      Error (TestFailed ("get_role: " ^ good_string ^ " /= " ^ bad_string)) in
    Test.get_role test_machine_role
    >>=? (fun role_desc ->
        if role_desc = expected
        then return @@ Ok ()
        else return @@ different_role_error role_desc)

  let test () =
    Common.test ()
    >>=? get_availability_zone_test
    >>=? get_region_test
    >>=? get_role_test
end

(* System tests are expected to run in the CI server and any devbox *)
module System = struct
  module Common = Make_common(Aws_async.Ec2_inst_meta)

  (* For some tests we just want to check that they return something that is
     not an error *)
  let ignore_result = fun _ -> ()

  let get_availability_zone_test () =
    Test.get_availability_zone ()
    >>|? ignore_result

  let get_region_test () =
    Aws_async.Ec2_inst_meta.get_region ()
    >>|? ignore_result

  (* Just check we get a successful result, actual JSON parsing is already
     tested by the unit tests *)
  let get_role_test () =
    Aws_async.Ec2_inst_meta.get_role test_machine_role
    >>|? (fun role_desc -> role_desc.Ec2im_iam_role_t.code)
    >>| match_with "Success" "get_role_test"

  let test () =
    Common.test ()
    >>=? get_availability_zone_test
    >>=? get_region_test
    >>=? get_role_test
end

let unit = Unit.test
let system = System.test
