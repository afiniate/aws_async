open Core.Std
open Async.Std
open Deferred.Result.Monad_infix

type return_attribute =
  | All
  | Approximate_first_receive_timestamp
  | Approximate_receive_count
  | Sender_id
  | Sent_timestamp

type attribute =
  | Approximate_first_receive_timestamp of Time.t
  | Approximate_receive_count of Int.t
  | Sender_id of String.t
  | Sent_timestamp of Time.t with sexp

type receipt_handle = Receipt_handle of String.t with sexp

type message = {md5:String.t;
                id:String.t;
                receipt_handle:receipt_handle;
                body:String.t;
                attributes:attribute List.t} with sexp

type result = {messages: message List.t;
               request_id:String.t} with sexp

type entry =
  | String of String.t
  | Attr of attribute

let long_poll_seconds = 20

let string_of_receipt_handle (Receipt_handle str) =
  str

let receipt_handle_of_string str =
  Receipt_handle str

let message_of_assoc_list assoc =
  let open Option.Monad_infix in
  let get_string = function
    | String value -> Some value
    | _ -> None in
  List.Assoc.find assoc "Body"
  >>= get_string
  >>= fun body ->
  List.Assoc.find assoc "ReceiptHandle"
  >>= get_string
  >>= fun receipt_handle ->
  List.Assoc.find assoc "MD5OfBody"
  >>= get_string
  >>= fun md5 ->
  List.Assoc.find assoc "MessageId"
  >>= get_string
  >>= fun id ->
  let attrs = List.fold assoc ~init:[]
      ~f:(fun acc ->
          function
          | ("Attribute", (Attr attr)) -> (attr::acc)
          | _ -> acc) in
  Some {md5=md5; id=id; receipt_handle=Receipt_handle receipt_handle;
        body=Sqs_util.decode_message_body body; attributes=attrs}

let make_attribute attr_name attr_value =
  match attr_name with
  | "SenderId" ->
    Ok (Sender_id attr_value)
  | "ApproximateFirstReceiveTimestamp" ->
    Ok (Approximate_first_receive_timestamp
          (Sqs_util.time_of_epoch_milli_string attr_value))
  | "ApproximateReceiveCount" ->
    Ok (Approximate_receive_count (Int.of_string attr_value))
  | "SentTimestamp" ->
    Ok (Sent_timestamp
          (Sqs_util.time_of_epoch_milli_string attr_value))
  | _ ->
    Result.fail (Sqs_system.Error
                   (Sqs_system.Invalid_attribute (attr_name, attr_value),
                    "Invalid attribute"))

let parse_attribute channel =
  let open Result.Monad_infix in
  Sqs_xml.expect_tag channel ~name:"Attribute"
  >>= Sqs_xml.extract_tag_body ~name:"Name"
  >>= fun (channel, attr_name) ->
  Sqs_xml.extract_tag_body channel ~name:"Value"
  >>= fun (channel, attr_value) ->
  make_attribute attr_name attr_value
  >>= fun attr ->
  Sqs_xml.expect_end channel
  >>= fun channel -> Ok (channel, ("Attribute", Attr attr))

let parse_element channel =
  let open Result.Monad_infix in
  function
  | "Body" ->
    Sqs_xml.extract_tag_body channel ~name:"Body"
    >>= fun (channel, body) ->
    Ok (channel, ("Body", String body))
  | "ReceiptHandle" ->
    Sqs_xml.extract_tag_body channel ~name:"ReceiptHandle"
    >>= fun (channel, rh) ->
    Ok (channel, ("ReceiptHandle", String rh))
  | "MD5OfBody" ->
    Sqs_xml.extract_tag_body channel ~name:"MD5OfBody"
    >>= fun (channel, md5) ->
    Ok (channel, ("MD5OfBody", String md5))
  | "MessageId" ->
    Sqs_xml.extract_tag_body channel ~name:"MessageId"
    >>= fun (channel, id) ->
    Ok (channel, ("MessageId", String id))
  | "Attribute" ->
    parse_attribute channel
  | el ->
    Result.fail (Sqs_system.Error
                   ((Sqs_system.Unexpected_xml_element el),
                    "Unexpected xml element in result"))


let rec parse_message_body channel ~acc =
  let open Result.Monad_infix in
  Sqs_xml.peek_type channel
  >>= function
  | (channel, Start name) ->
    parse_element channel name
    >>= fun (channel, el) ->
    parse_message_body channel ~acc:(el::acc)
  | (channel, End) ->
    (match message_of_assoc_list acc with
     | Some msg ->
       Ok (channel, msg)
     | None ->
       Result.fail @@ Sqs_system.Error
         (Sqs_system.Parse_error,
          "Invalid xml format"))
and parse_message channel ~acc =
  let open Result.Monad_infix in
  Sqs_xml.expect_tag channel ~name:"Message"
  >>= parse_message_body ~acc:[]
  >>= fun (channel, msg) ->
  Sqs_xml.expect_end channel
  >>= parse_messages ~acc:(msg::acc)
and parse_messages channel ~acc =
  Sqs_xml.do_if_tag channel ~name:"Message"
    (parse_message ~acc)
    (fun channel ->
       Ok (channel, List.rev acc))

let parse_result xml_string =
  let open Result.Monad_infix in
  let parse_receive_message_result channel =
    Sqs_xml.expect_tag channel ~name:"ReceiveMessageResult"
    >>= parse_messages ~acc:[]
    >>= fun (channel, messages) ->
    Sqs_xml.expect_end channel
    >>= fun channel ->
    Ok (channel, messages) in
  Sqs_xml.expect_dtd @@ Xmlm.make_input (`String (0, xml_string))
  >>= Sqs_xml.expect_tag ~name:"ReceiveMessageResponse"
  >>= parse_receive_message_result
  >>= fun (channel, messages) ->
  Sqs_util.parse_response_metadata channel
  >>= fun (channel, request_id) ->
  Ok {messages = messages; request_id = request_id}

let convert_return_attribute attr =
  match attr with
  | All ->
    "All"
  | Approximate_first_receive_timestamp ->
    "ApproximateFirstReceiveTimestamp"
  | Approximate_receive_count ->
    "ApproximateReceiveCount"
  | Sender_id ->
    "SenderId"
  | Sent_timestamp ->
    "SentTimestamp"

let exec sys
    ?return_attributes
    ?max_number_of_messages
    ?visibility_timeout
    ?wait_time_seconds
    url =
  let url' = url
             |> Sqs_util.add_standard_param ~name:"Action"
               ~value:"ReceiveMessage"
             |> Sqs_util.counted_param ~name:"AttributeName"
               ~converter:convert_return_attribute
               ~values:return_attributes
             |> Sqs_util.add_param ~name:"MaxNumberOfMessages"
               ~converter:Int.to_string
               ~value:max_number_of_messages
             |> Sqs_util.add_param ~name:"VisibilityTimeout"
               ~converter:Int.to_string
               ~value:visibility_timeout
             |>  Sqs_util.add_param ~name:"WaitTimeSeconds"
               ~converter:Int.to_string
               ~value:wait_time_seconds in
  Sqs_request.get sys.Sqs_system.auth "" url'
  >>= fun (auth, body) ->
  match parse_result body with
  | Ok response ->
    return @@ Ok ({sys with auth}, response)
  | Error err ->
    return @@ Result.fail err

let long_poll sys
    ?return_attributes
    ?max_number_of_messages
    ?visibility_timeout
    url =
  exec sys ?return_attributes ?max_number_of_messages ?visibility_timeout
    ~wait_time_seconds:long_poll_seconds url

let name_exec sys
    ?return_attributes
    ?max_number_of_messages
    ?visibility_timeout
    ?wait_time_seconds
    name =
  Sqs_getqueueurl.exec sys name
  >>= fun (sys', {Sqs_getqueueurl.queue_url = queue_url}) ->
  exec sys' ?return_attributes ?max_number_of_messages ?visibility_timeout
    ?wait_time_seconds queue_url

let name_long_poll sys
    ?return_attributes
    ?max_number_of_messages
    ?visibility_timeout
    name =
  Sqs_getqueueurl.exec sys name
  >>= fun (sys', {Sqs_getqueueurl.queue_url = queue_url}) ->
  exec sys' ?return_attributes ?max_number_of_messages ?visibility_timeout
    ~wait_time_seconds:long_poll_seconds queue_url
