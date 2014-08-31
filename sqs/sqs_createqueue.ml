open Core.Std
open Async.Std
open Deferred.Result.Monad_infix

type result = {queue_url:Uri.t;
               request_id:String.t} with sexp

let parse_result xml_string =
  let open Result.Monad_infix in
  let parse_queue_url channel =
    Sqs_xml.expect_tag channel ~name:"CreateQueueResult"
    >>= Sqs_xml.extract_tag_body ~name:"QueueUrl"
    >>= fun (channel, url) ->
    Sqs_xml.expect_end channel
    >>= fun channel ->
    Ok (channel, url) in
  Sqs_xml.expect_dtd @@ Xmlm.make_input (`String (0, xml_string))
  >>= Sqs_xml.expect_tag ~name:"CreateQueueResponse"
  >>= parse_queue_url
  >>= fun (channel, url) ->
  Sqs_util.parse_response_metadata channel
  >>= fun (channel, request_id) ->
  Ok {queue_url = Uri.of_string url; request_id = request_id}

let exec sys
         ?delay_seconds
         ?maximum_message_size
         ?message_retention_period
         ?policy
         ?receive_message_wait_time_seconds
         ?visibility_timeout
         name =
  let (uri, _) = sys.Sqs_system.url
                 |> Sqs_util.add_standard_param ~name:"QueueName"
                                                ~value:name
                 |> Sqs_util.add_standard_param ~name:"Action"
                                                ~value:"CreateQueue"
                 |>  Sqs_util.convert_output
                 |> Sqs_util.add_list_param ~name:"DelaySeconds"
                                            ~converter:Int.to_string
                                            ~value:delay_seconds
                 |> Sqs_util.add_list_param ~name:"MaximumMessageSize"
                                            ~converter:Int.to_string
                                            ~value:maximum_message_size
                 |>  Sqs_util.add_list_param ~name:"MessageRetentionPeriod"
                                             ~converter:Int.to_string
                                             ~value:message_retention_period
                 |> Sqs_util.add_list_param ~name:"Policy"
                                            ~converter:Sqs_policy_j.string_of_policy
                                            ~value:policy
                 |>  Sqs_util.add_list_param ~name:"MessageRetentionPeriod"
                                             ~converter:Int.to_string
                                             ~value:message_retention_period
                 |> Sqs_util.add_list_param ~name:"ReceiveMessageWaitTimeSeconds"
                                            ~converter:Int.to_string
                                            ~value:receive_message_wait_time_seconds
                 |>  Sqs_util.add_list_param ~name:"VisibilityTimeout"
                                             ~converter:Int.to_string
                                             ~value:visibility_timeout in
  Sqs_request.get sys.auth "" uri
  >>= fun (auth, body) ->
  match parse_result body with
  | Ok response ->
     return @@ Ok ({sys with auth}, response)
  | Error err ->
     return @@ Result.fail err
