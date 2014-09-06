open Core.Std
open Async.Std

type headers = (String.t * String.t) List.t

let try_parse ~sys ~f (auth, str) =
  try
    return @@ Ok ({sys with Ddb_system.auth}, f str)
  with
    _ -> return @@
    Error
      (Ddb_system.Error
         (Ddb_system.Internal_failure,
          "Unable to parse result message: " ^ str))

(*
 *  This exists because Amazon occasionally returns a message with
 * 'Message' as the field and at other times returns an error with
 * 'message' as the field. Though it *always* returns one of those two,
 * we have to take into account the crazy
 *)
let get_message message1 message2 =
  match message1 with
  | Some msg -> msg
  | None ->
    (match message2 with
     | Some msg -> msg
     | None -> "")

let parse_error {Ddb_base_t.code; message1; message2} =
  let convert = function
    | "AccessDeniedException" ->
      Ddb_system.Access_denied
    | "ConditionalCheckFailedException" ->
      Ddb_system.Conditional_check_failed
    | "IncompleteSignatureException" ->
      Ddb_system.Incomplete_signature
    | "ItemCollectionSizeLimitExceededException" ->
      Ddb_system.Item_collection_size_limit_exceeded
    | "LimitExceededException" ->
      Ddb_system.Limit_exceeded
    | "MissingAuthenticationTokenException" ->
      Ddb_system.Missing_authentication_token
    | "ProvisionedThroughputExceededException" ->
      Ddb_system.Provisioned_throughput_exceeded
    | "ResourceInUseException" ->
      Ddb_system.Resource_in_use
    | "ResourceNotFoundException" ->
      Ddb_system.Resource_not_found
    | "ThrottlingException" ->
      Ddb_system.Throttling
    | "UnrecognizedClientException" ->
      Ddb_system.Unrecognized_client
    | "ValidationException" ->
      Ddb_system.Validation_error
    | "" ->
      Ddb_system.Entity_too_large
    | "InternalFailure" ->
      Ddb_system.Internal_failure
    | "InternalServerError" ->
      Ddb_system.Internal_server_error
    | "ServiceUnavailableException" ->
      Ddb_system.Service_unavailable
    | "InvalidAction" ->
      Ddb_system.Invalid_action
    | "InvalidClientTokenId" ->
      Ddb_system.Invalid_client_token_id
    | "InvalidParameterCombination" ->
      Ddb_system.Invalid_parameter_combination
    | "InvalidParameterValue" ->
      Ddb_system.Invalid_parameter_value
    | "InvalidQueryParameter" ->
      Ddb_system.Invalid_query_parameter
    | "MalformedQueryString" ->
      Ddb_system.Malformed_query_string
    | "MissingAction" ->
      Ddb_system.Missing_action
    | "MissingParameter" ->
      Ddb_system.Missing_parameter
    | "OptInRequired" ->
      Ddb_system.Opt_in_required
    | "RequestExpired" ->
      Ddb_system.Request_expired
    | mt ->
      Ddb_system.Invalid_error_type mt in
  match String.split code '#' with
  | [_; message_type] ->
    Ddb_system.Error (convert message_type, get_message message1 message1)
  | _ ->
    Ddb_system.Error (Ddb_system.Invalid_error_type code,
                      get_message message1 message2)

let cohttp_post url body (auth, authed_headers) =
  let open Deferred.Monad_infix in
  let cohttp_headers = Cohttp.Header.of_list authed_headers in
  let async_body = Cohttp_async.Body.of_string body in
  Cohttp_async.Client.post ~headers:cohttp_headers ~body:async_body url
  >>= fun (resp, body) ->
  Cohttp_async.Body.to_string body
  >>= fun str_body ->
  if `OK = Cohttp.Response.status resp then
    return @@ Ok (auth, str_body)
  else
    try
      return @@ Error (parse_error @@ Ddb_base_j.error_of_string str_body)
    with
      _ ->
      return @@ Error (Ddb_system.Error
                         (Ddb_system.Internal_failure,
                          "Unable to parse error message: " ^ str_body))


let post auth headers body url =
  let body_len = String.length body in
  let headers' = ("content-type", "application/x-amz-json-1.0")::
                 ("content-length", string_of_int body_len)::headers in
  let open Deferred.Result in
  Aws_auth.v4_authorize auth
    Ddb_system.service_name
    "POST"
    url
    headers'
    body
  >>= cohttp_post url body
