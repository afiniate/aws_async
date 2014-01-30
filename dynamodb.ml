open Core.Std
open Async.Std

type t = {auth: Auth.t;
          region: String.t;
          url: Uri.t}

type key_value = Dynamodb_getitem_t.key_value = {
                 b: string option;
                 bs: string list option;
                 s: string option;
                 ss: string list option;
                 n: string option;
                 ns: string list option
               }

type index_capacity_unit = Dynamodb_getitem_t.index_capacity_unit =
                             { capacity_units: float }

type index_capacity_units = Dynamodb_getitem_t.index_capacity_units

type consumed_capacity = Dynamodb_getitem_t.consumed_capacity = {
                         capacity_units: float;
                         global_secondary_indexes: index_capacity_units;
                         local_secondary_indexes: index_capacity_units;
                         table_capacity: index_capacity_units;
                         table_name: string
                       }

type result = Dynamodb_getitem_t.result = {
              consumed_capacity: consumed_capacity option;
              item: (string * key_value) list
            }


type return_consumed_capacity = Dynamodb_getitem_t.return_consumed_capacity

type query =
  | Binary of String.t
  | BinarySet of String.t List.t
  | Int of Int.t
  | IntSet of Int.t List.t
  | Float of Float.t
  | FloatSet of Float.t List.t
  | Number of String.t
  | NumberSet of String.t List.t
  | String of String.t
  | StringSet of String.t List.t

let service = "dynamodb"
let api_version = "DynamoDB_20120810"

let make_attribute_name name =
  let open Or_error in
  let name_len = String.length name in
  if name_len >= 1 &&
       name_len <= 255
  then error
         "Attribute name is too: long, must be at least 1 char and less then 255"
         name
         String.sexp_of_t
  else return name

let get_item sys
             ?attributes
             ?consistent_read
             ?return_consumed_capacity
             table_name
             keys =
  let request_spec = api_version ^ ".GetItem" in
  let attribute_keys =
    List.map keys
             ~f:(fun (n, v) ->
                 let v' = match v with
                   | Binary b ->
                      {Dynamodb_getitem_t.b = Some b;
                       bs = None; s = None; ss = None;
                       n = None; ns = None}
                   | BinarySet bs ->
                      {bs = Some bs;
                       b = None; s = None; ss = None;
                       n = None; ns = None}
                   | Int i ->
                      {n = Some (string_of_int i);
                       ns = None; s = None; ss = None;
                       b = None; bs = None}
                   | IntSet is ->
                      {ns = Some (List.map ~f:(fun x -> string_of_int x) is);
                       n = None; s = None; ss = None;
                       b = None; bs = None}
                   | Float f ->
                      {n = Some (Float.to_string f);
                       ns = None; s = None; ss = None;
                       b = None; bs = None}
                   | FloatSet fs ->
                      {ns = Some (List.map ~f:(fun x -> Float.to_string x) fs);
                       n = None; s = None; ss = None;
                       b = None; bs = None}
                   | Number n ->
                      {n = Some n;
                       ns = None; s = None; ss = None;
                       b = None; bs = None}
                   | NumberSet ns ->
                      {ns = Some ns;
                       n = None; s = None; ss = None;
                       b = None; bs = None}
                   | String s ->
                      {s = Some s;
                       ss = None; n = None;
                       ns = None; b = None;
                       bs = None}
                   | StringSet ss ->
                      {ss = Some ss;
                       s = None; n = None; ns = None;
                       b = None; bs = None} in
                 (n, v')) in
  let json = Dynamodb_getitem_j.string_of_get_item {attributes;
                                            consistent_read=consistent_read;
                                            key = attribute_keys;
                                            return_consumed_capacity;
                                            table_name = table_name} in
  (Request.post sys.auth
                service [("x-amz-target", request_spec);
                         ("Content-Type", "application/x-amz-json-1.0")]
                json
                sys.url)
  >>= fun (resp, body) -> Cohttp_async.body_to_string body
  >>= fun str_body ->
      if `OK = Cohttp.Response.status resp then
        Deferred.Or_error.try_with
          (fun () ->
           return (resp, Dynamodb_getitem_j.result_of_string str_body))
      else
        return (error "Invalid response"
                      (resp, str_body)
                      Request.sexp_of_response)



let create ?url access_id secret_key region =
  let make_url = match url with
    | None -> Uri.of_string ("http://dynamodb." ^
                               region ^ ".amazonaws.com")
    | Some new_url -> Uri.of_string new_url in
  {auth = Auth.create access_id secret_key region;
   region = region;
   url = make_url}
