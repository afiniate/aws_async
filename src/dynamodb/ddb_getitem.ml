open Core.Std
open Async.Std

type keys = Ddb_system.attribute List.t

let exec sys
    ?attributes
    ?consistent_read
    ?return_consumed_capacity
    table_name
    key =
  let request_spec = Ddb_system.api_version ^ ".GetItem" in
  let json = Ddb_getitem_j.string_of_get_item {attributes;
                                               consistent_read=consistent_read;
                                               key;
                                               return_consumed_capacity;
                                               table_name = table_name} in
  let open Deferred.Result in
  Ddb_request.post sys.Ddb_system.auth  [("x-amz-target", request_spec);
                                         ("Content-Type", "application/x-amz-json-1.0")]
    json sys.url
  >>= Ddb_request.try_parse ~sys ~f:Ddb_getitem_j.result_of_string
