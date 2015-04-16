open Core.Std
open Result.Monad_infix

let counted_param uri ~name ~converter ~values =
  match values with
  | Some data ->
    List.foldi ~init:uri
      ~f:(fun index new_uri element ->
          let attr_name = name (* ^ "." ^ (Int.to_string (index + 1))o *) in
          Uri.add_query_param' uri (attr_name, converter element)) data
  | None -> uri

let add_list_param (uri, count) ~name ~converter ~value =
  match value with
  | Some data ->
    let attr = "Attribute." ^ (Int.to_string count)in
    let attr_name = attr ^ ".name" in
    let attr_value = attr ^ ".value" in
    (Uri.add_query_params' uri [(attr_name, name);
                                (attr_value, (converter data))],
     count + 1)
  | None -> (uri, count)

let add_param uri ~name ~converter ~value =
  match value with
  | Some data ->
    Uri.add_query_params' uri [(name, (converter data))]
  | None -> uri

let add_standard_param uri ~name ~value =
  Uri.add_query_param' uri (name, value)

let convert_output uri =
  (uri, 1)

let parse_response_metadata channel =
  Sqs_xml.expect_tag channel ~name:"ResponseMetadata"
  >>= Sqs_xml.extract_tag_body ~name:"RequestId"
  >>= fun (channel, request_id) ->
  Sqs_xml.expect_end channel
  >>= Sqs_xml.expect_end
  >>= fun channel ->
  Ok (channel, request_id)

let convert_string str = str

let encode_message_body = B64.encode ~pad:true ?alphabet:None
let decode_message_body = B64.decode ?alphabet:None

let time_of_epoch_milli_string value =
  Time.of_float (Float.of_string value /. 1000.0)
