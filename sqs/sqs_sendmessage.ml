open Core.Std
open Async.Std
open Deferred.Result.Monad_infix

type result = {message_md5:String.t;
               message_id:String.t;
               request_id:String.t} with sexp

let parse_result xml_string =
  let open Result.Monad_infix in
  let parse_send_message_result channel =
    Sqs_xml.expect_tag channel ~name:"SendMessageResult"
    >>= Sqs_xml.extract_tag_body ~name:"MessageId"
    >>= fun (channel, id) ->
    Sqs_xml.extract_tag_body channel ~name:"MD5OfMessageBody"
    >>= fun (channel, md5) ->
    Sqs_xml.expect_end channel
    >>= fun channel ->
    Ok (channel, md5, id) in
  Sqs_xml.expect_dtd @@ Xmlm.make_input (`String (0, xml_string))
  >>= Sqs_xml.expect_tag ~name:"SendMessageResponse"
  >>= parse_send_message_result
  >>= fun (channel, md5, id) ->
  Sqs_util.parse_response_metadata channel
  >>= fun (channel, request_id) ->
  Ok {message_md5 = md5; message_id = id; request_id = id}

let exec sys
         ?delay_seconds
         ~queue_url
         message_body =
  let uri = queue_url
            |> Sqs_util.add_standard_param ~name:"Action"
                                           ~value:"SendMessage"
            |> Sqs_util.add_standard_param ~name:"MessageBody"
                                           ~value:(Sqs_util.encode_message_body message_body)
            |> Sqs_util.add_param ~name:"DelaySeconds"
                                  ~converter:Int.to_string
                                  ~value:delay_seconds in
  Sqs_request.get sys.Sqs_system.auth "" uri
  >>= fun (auth, body) ->
  match parse_result body with
  | Ok response ->
     return @@ Ok ({sys with auth}, response)
  | Error err ->
     return @@ Result.fail err

let name_exec sys
              ?delay_seconds
              ~queue_name
              message_body =
  Sqs_getqueueurl.exec sys queue_name
  >>= fun (sys', {Sqs_getqueueurl.queue_url = queue_url}) ->
  exec sys' ?delay_seconds ~queue_url message_body
