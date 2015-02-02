open Core.Std
open Async.Std
open Deferred.Result.Monad_infix

type result = {request_id:String.t} with sexp

let parse_result xml_string =
  let open Result.Monad_infix in
  Sqs_xml.expect_dtd @@ Xmlm.make_input (`String (0, xml_string))
  >>= Sqs_xml.expect_tag ~name:"DeleteQueueResponse"
  >>= Sqs_util.parse_response_metadata
  >>= fun (channel, request_id) ->
  Ok {request_id = request_id}

let exec sys
    url =
  let uri = url
            |> Sqs_util.add_standard_param ~name:"Action"
              ~value:"DeleteQueue" in
  Sqs_request.get sys.Sqs_system.auth "" uri
  >>= fun (auth, body) ->
  match parse_result body with
  | Ok response ->
    return @@ Ok ({sys with auth}, response)
  | Error err ->
    return @@ Result.fail err
