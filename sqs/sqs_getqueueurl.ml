open Core.Std
open Async.Std
open Deferred.Result.Monad_infix

type result = {queue_url:Uri.t;
               request_id:String.t} with sexp

let parse_result xml_string =
  let open Result.Monad_infix in
  let parse_queue_url channel =
    Sqs_xml.expect_tag channel ~name:"GetQueueUrlResult"
    >>= Sqs_xml.extract_tag_body ~name:"QueueUrl"
    >>= fun (channel, url) ->
    Sqs_xml.expect_end channel
    >>= fun channel ->
    Ok (channel, url) in
  Sqs_xml.expect_dtd @@ Xmlm.make_input (`String (0, xml_string))
  >>= Sqs_xml.expect_tag ~name:"GetQueueUrlResponse"
  >>= parse_queue_url
  >>= fun (channel, url) ->
  Sqs_util.parse_response_metadata channel
  >>= fun (channel, request_id) ->
  Ok {queue_url = Uri.of_string url; request_id = request_id}

let exec sys
    ?queue_owner_aws_account_id
    name =
  let uri = sys.Sqs_system.url
            |> Sqs_util.add_standard_param ~name:"QueueName"
              ~value:name
            |> Sqs_util.add_standard_param ~name:"Action"
              ~value:"GetQueueUrl"
            |> Sqs_util.add_param ~name:"QueueOwnerAWSAccountId"
              ~converter:Sqs_util.convert_string
              ~value:queue_owner_aws_account_id in
  Sqs_request.get sys.auth "" uri
  >>= fun (auth, body) ->
  match parse_result body with
  | Ok response ->
    return @@ Ok ({sys with auth}, response)
  | Error err ->
    return @@ Result.fail err
