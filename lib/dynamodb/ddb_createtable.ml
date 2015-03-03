open Core.Std
open Async.Std

let exec sys
    table =
  let request_spec = Ddb_system.api_version ^ ".CreateTable" in
  let json = Ddb_createtable_j.string_of_table table in
  let open Deferred.Result in
  Ddb_request.post
    sys.Ddb_system.auth
    [("x-amz-target", request_spec);
     ("Content-Type", "application/x-amz-json-1.0")]
    json
    sys.url
  >>= Ddb_request.try_parse ~sys ~f:Ddb_createtable_j.result_of_string
