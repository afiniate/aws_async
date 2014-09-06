open Core.Std
open Async.Std

type keys = Ddb_system.attribute List.t

type condition =
  | Eq of Ddb_system.attribute_value List.t
  | Ne of Ddb_system.attribute_value List.t
  | Le of Ddb_system.attribute_value List.t
  | Lt of Ddb_system.attribute_value List.t
  | Ge of Ddb_system.attribute_value List.t
  | Gt of Ddb_system.attribute_value List.t
  | Not_null of Ddb_system.attribute_value List.t
  | Null of Ddb_system.attribute_value List.t
  | Contains of Ddb_system.attribute_value List.t
  | Not_contains of Ddb_system.attribute_value List.t
  | Begins_with of Ddb_system.attribute_value List.t
  | Between of Ddb_system.attribute_value List.t

type filter =
  | And of (String.t * condition) List.t
  | Or of (String.t * condition) List.t

let filter_to_key =
  function
  | Eq attr_list ->
    {Ddb_scan_t.attribute_value_list = attr_list;
     comparison_operator = `EQ}
  | Ne attr_list ->
    {Ddb_scan_t.attribute_value_list = attr_list;
     comparison_operator = `NE}
  | Le attr_list ->
    {Ddb_scan_t.attribute_value_list = attr_list;
     comparison_operator = `LE}
  | Lt attr_list ->
    {Ddb_scan_t.attribute_value_list = attr_list;
     comparison_operator = `LT}
  | Ge attr_list ->
    {Ddb_scan_t.attribute_value_list = attr_list;
     comparison_operator = `GE}
  | Gt attr_list ->
    {Ddb_scan_t.attribute_value_list = attr_list;
     comparison_operator = `GT}
  | Null attr_list ->
    {Ddb_scan_t.attribute_value_list = attr_list;
     comparison_operator = `NULL}
  | Not_null attr_list ->
    {Ddb_scan_t.attribute_value_list = attr_list;
     comparison_operator = `NOT_NULL}
  | Contains attr_list ->
    {Ddb_scan_t.attribute_value_list = attr_list;
     comparison_operator = `CONTAINS}
  | Not_contains attr_list ->
    {Ddb_scan_t.attribute_value_list = attr_list;
     comparison_operator = `NOT_CONTAINS}
  | Begins_with attr_list ->
    {Ddb_scan_t.attribute_value_list = attr_list;
     comparison_operator = `BEGINS_WITH}
  | Between attr_list ->
    {Ddb_scan_t.attribute_value_list = attr_list;
     comparison_operator = `BETWEEN}

let filter_to_filter_list =
  List.map ~f:(fun (n, v) ->
      (n, filter_to_key v))

let exec sys
    ?attributes
    ?exclusive_start_key
    ?limit
    ?return_consumed_capacity
    ?filter
    ?segment
    ?total_segments
    ?select
    table_name =

  let request_spec = Ddb_system.api_version ^ ".Scan" in
  let json = let open Option.Monad_infix in
    let fd = filter
      >>= function
      | And fdp -> Some (filter_to_filter_list fdp)
      | Or fdp -> Some (filter_to_filter_list fdp) in
    let operator = filter
      >>= function
      | And [] -> None
      | Or [] -> None
      | And _ -> Some `AND
      | Or _ -> Some `OR in
    Ddb_scan_j.string_of_scan
      {attributes;
       conditional_operator = operator;
       exclusive_start_key;
       limit;
       return_consumed_capacity;
       scan_filter = fd;
       segment;
       select;
       total_segments;
       table_name} in
  let open Deferred.Result in
  Ddb_request.post sys.Ddb_system.auth [("x-amz-target", request_spec);
                                        ("Content-Type", "application/x-amz-json-1.0")]
    json sys.url
  >>= Ddb_request.try_parse ~sys ~f:Ddb_scan_j.result_of_string

let all sys
    ?attributes
    ?exclusive_start_key
    ?limit
    ?return_consumed_capacity
    ?segment
    ?total_segments
    ?select
    table_name =
  exec sys ?attributes ?exclusive_start_key ?limit
    ?return_consumed_capacity ?segment
    ?total_segments ?select  ~filter:(And []) table_name
