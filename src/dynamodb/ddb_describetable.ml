open Core.Std
open Async.Std

let exec sys
    table_name =
  let request_spec = Ddb_system.api_version ^ ".DescribeTable" in
  let json = Ddb_describetable_j.string_of_describe_table
      {Ddb_describetable_t.table_name = table_name} in
  let open Deferred.Result in
  (Ddb_request.post
     sys.Ddb_system.auth
     [("x-amz-target", request_spec);
      ("Content-Type", "application/x-amz-json-1.0")]
     json
     sys.url)
  >>= Ddb_request.try_parse ~sys ~f:Ddb_describetable_j.result_of_string
