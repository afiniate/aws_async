open Core.Std
open Async.Std

type keys = Ddb_system.attribute List.t

type condition =
  | Eq of Ddb_system.attribute_value List.t
  | Le of Ddb_system.attribute_value List.t
  | Lt of Ddb_system.attribute_value List.t
  | Ge of Ddb_system.attribute_value List.t
  | Gt of Ddb_system.attribute_value List.t
  | Begins_with of Ddb_system.attribute_value List.t
  | Between of Ddb_system.attribute_value List.t

type query = (String.t * condition) List.t

let query_to_key =
  function
  | Eq attr_list ->
     {Ddb_query_t.attribute_value_list = attr_list;
     comparison_operator = `EQ}
  | Le attr_list ->
     {Ddb_query_t.attribute_value_list = attr_list;
     comparison_operator = `LE}
  | Lt attr_list ->
     {Ddb_query_t.attribute_value_list = attr_list;
     comparison_operator = `LT}
  | Ge attr_list ->
     {Ddb_query_t.attribute_value_list = attr_list;
     comparison_operator = `GE}
  | Gt attr_list ->
     {Ddb_query_t.attribute_value_list = attr_list;
     comparison_operator = `GT}
  | Begins_with attr_list ->
     {Ddb_query_t.attribute_value_list = attr_list;
     comparison_operator = `BEGINS_WITH}
  | Between attr_list ->
     {Ddb_query_t.attribute_value_list = attr_list;
      comparison_operator = `BETWEEN}

let query_to_query_list =
  List.map ~f:(fun (n, v) ->
               (n, query_to_key v))

let exec sys
         ?attributes
         ?consistent_read
         ?exclusive_start_key
         ?index_name
         ?query
         ?limit
         ?return_consumed_capacity
         ?scan_index_forward
         ?select
         table_name =

  let request_spec = Ddb_system.api_version ^ ".Query" in

  let json = let open Option.Monad_infix in
             let qd = query
                      >>= fun qdp -> Some (query_to_query_list qdp) in
             Ddb_query_j.string_of_query
               {attributes;
                consistent_read;
                exclusive_start_key;
                index_name;
                key_conditions = qd;
                limit;
                return_consumed_capacity;
                scan_index_forward;
                select;
                table_name} in
  let open Deferred.Result in
  Ddb_request.post sys.Ddb_system.auth [("x-amz-target", request_spec);
                                        ("Content-Type", "application/x-amz-json-1.0")]
                   json sys.url
  >>= Ddb_request.try_parse ~sys ~f:Ddb_query_j.result_of_string
