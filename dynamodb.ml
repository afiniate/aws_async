open Core
open Core.Std
open Async.Std

type t = {auth: Auth.t;
          region: String.t;
          url: Uri.t}

type return_consumed_capacity = NONE | TOTAL

type query =
  | Binary of String.t
  | BinarySet of String.t List.t
  | Int of Int.t
  | IntSet of Int.t List.t
  | Float of Float.t
  | FloatSet of Float.t List.t
  | String of String.t
  | StringSet of String.t List.t

let service = "dynamodb"
let api_version = "DynamoDB_20120810"

let get_item sys ?(attributes_to_get = [])
             ?(consistent_read = false)
             ?(return_consumed_capacity = NONE)
             table_name
             keys =
  let attr_json = function
    | [] -> []
    | _ -> [("AttributesToGet",
             `List (List.map attributes_to_get
                             ~f:(fun x -> `String x)))] in
  let request_spec = api_version ^ ".GetItem" in
  let convert_capacity = function
    | NONE -> `String "NONE"
    | TOTAL -> `String "TOTAL" in
  let attribute_keys =
    `Assoc
     (List.map keys
               ~f:(fun (n, v) ->
                   let v' = match v with
                     | Binary s ->
                        `Assoc [("B", `String s)]
                     | BinarySet ss ->
                        `Assoc [("BS",
                                 `List
                                  (List.map ss ~f: (fun x ->
                                                    `String x)))]
                     | Int i ->
                        `Assoc [("N", `String (string_of_int i))]
                     | IntSet is ->
                        `Assoc [("NS",
                                 `List (List.map is
                                                 ~f:(fun x ->
                                                     `String (string_of_int x))))]
                     | Float f ->
                        `Assoc [("N", `String (Float.to_string f))]
                     | FloatSet fs ->
                        `Assoc [("NS",
                                 `List (List.map fs
                                                 ~f:(fun x ->
                                                     `String (Float.to_string x))))]
                     | String s ->
                        `Assoc [("S", `String s)]
                     | StringSet ss ->
                        `Assoc [("SS",
                                 `List (List.map ss
                                                 ~f:(fun x ->
                                                     `String x)))] in
                   (n, v'))) in
  let json = Yojson.Safe.to_string
               (`Assoc
                 (List.concat [attr_json attributes_to_get;
                               [("ConsistentRead", `Bool consistent_read);
                                ("Key", attribute_keys);
                                ("ReturnConsumedCapacity",
                                 convert_capacity
                                   return_consumed_capacity);
                                ("TableName", `String table_name)]])) in
  Request.post sys.auth service [("x-amz-target", request_spec)] json sys.url

let create ?url access_id secret_key region =
  let make_url = match url with
    | None -> Uri.of_string ("http://dynamodb." ^
                               region ^ ".amazonaws.com")
    | Some new_url -> Uri.of_string new_url in
  {auth = Auth.create access_id secret_key region;
   region = region;
   url = make_url}
