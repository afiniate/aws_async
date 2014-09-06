open Core.Std
open Async.Std

type headers = (string * string) list

let parse_error xml_string =
  let open Result.Monad_infix in
  let parse_error channel =
    Sqs_xml.expect_tag channel ~name:"Error"
    >>= Sqs_xml.extract_tag_body ~name:"Type"
    >>= fun (channel, t) ->
    Sqs_xml.expect_end channel
    >>= Sqs_xml.extract_tag_body ~name:"Code"
    >>= fun (channel, code) ->
    Sqs_xml.expect_end channel
    >>= Sqs_xml.extract_tag_body ~name:"Message"
    >>= fun (channel, message) ->
    Sqs_xml.expect_end channel
    >>= Sqs_xml.extract_tag_body ~name:"Detail"
    >>= fun (channel, detail) ->
    Sqs_xml.expect_end channel
    >>= Sqs_xml.expect_end
    >>= fun channel ->
    Ok (channel, t, code, message, detail) in
  let parse_request_id (channel, t, code, message, detail) =
    Sqs_xml.extract_tag_body channel ~name:"RequestId"
    >>= fun (channel, id) ->
    Sqs_xml.expect_end channel
    >>= fun channel ->
    Ok (channel, {Sqs_system.t = t;
                  code = code;
                  message = message;
                  detail = detail;
                  request_id = id}) in
  Sqs_xml.expect_dtd @@ Xmlm.make_input (`String (0, xml_string))
  >>= Sqs_xml.expect_tag ~name:"ErrorResponse"
  >>= parse_error
  >>= parse_request_id
  >>= fun (channel, result) ->
  Sqs_xml.expect_end channel
  >>= fun channel ->
  Ok result

let get_with_headers body url (auth, authed_headers) =
  let cohttp_headers = Cohttp.Header.of_list authed_headers in
  Cohttp_async.Client.get ~headers:cohttp_headers url
  >>= fun (resp, body) ->
  Cohttp_async.Body.to_string body
  >>= fun str_body ->
  if `OK = Cohttp.Response.status resp then
    return @@ Ok (auth, str_body)
  else
    match parse_error str_body with
    | Ok error ->
      return @@ Error (Sqs_system.Error
                         (Sqs_system.Service_error error,
                          "Sqs system error"))
    | Error err ->
      return @@ Error err


let get auth body url =
  let open Deferred.Result in
  Aws_auth.v4_authorize auth Sqs_system.service "GET" url [] ""
  >>= get_with_headers body url
