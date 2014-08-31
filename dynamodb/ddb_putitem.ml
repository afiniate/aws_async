open Core.Std
open Async.Std


let exec sys
         ?expected
         ?return_consumed_capacity
         ?return_collection_metrics
         ?return_values
         table_name
         item =
  let request_spec = Ddb_system.api_version ^ ".PutItem" in

  let json = Ddb_putitem_j.string_of_put_item
               {expected;
                item;
                return_consumed_capacity;
                return_collection_metrics;
                return_values;
                table_name = table_name} in
  let open Deferred.Result in
  Ddb_request.post sys.Ddb_system.auth [("x-amz-target", request_spec);
                                        ("Content-Type", "application/x-amz-json-1.0")]
                   json sys.url
  >>= Ddb_request.try_parse ~sys ~f:Ddb_putitem_j.result_of_string
