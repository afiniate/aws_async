open Core.Std
open Async.Std

let exec sys
         ?exclusive_start_table_name
         ?limit () =
  let request_spec = Ddb_system.api_version ^ ".ListTables" in
  let json = Ddb_listtables_j.string_of_list_tables
               {Ddb_listtables_t.exclusive_start_table_name =
                  exclusive_start_table_name;
                limit = limit} in
  let open Deferred.Result in
  Ddb_request.post sys.Ddb_system.auth [("x-amz-target", request_spec);
                                        ("Content-Type", "application/x-amz-json-1.0")]
                   json
                   sys.url
  >>= Ddb_request.try_parse ~sys ~f:Ddb_listtables_j.result_of_string
