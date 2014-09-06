open Core.Std
open Async.Std

type t = Awsa_base.t
type headers = Awsa_headers.t

let credential_scope_value sys request_date service =
  let date = Awsa_date.to_year_form_string request_date in
  date ^ "/" ^ sys.Awsa_base.region ^ "/" ^ service ^ "/aws4_request"

let signing_key sys request_date service =
  let date = Awsa_date.to_year_form_string request_date in
  let ksecret = sys.Awsa_base.secret_access_key in
  let kdate = Awsa_sign.sign ("AWS4" ^ ksecret) date in
  let kregion = Awsa_sign.sign kdate sys.Awsa_base.region in
  let kservice = Awsa_sign.sign kregion service in
  Awsa_sign.sign kservice "aws4_request"

let string_to_sign sys request_date service httpMethod uri headers body =
  let (signed_headers, request_sig) =
    Awsa_cn_req.signature httpMethod uri headers body in
  let date = Awsa_date.to_basic_string request_date in
  let sts = Awsa_sign.algo ^ "\n" ^
            date ^ "\n" ^
            (credential_scope_value
               sys request_date service) ^ "\n" ^
            request_sig in
  (signed_headers, sts)

let sign_request sys request_date service
    httpMethod uri headers body =
  let (signed_headers, ss) = string_to_sign sys request_date service
      httpMethod uri headers body in
  let key = signing_key sys request_date service in
  (signed_headers, (Awsa_sign.sign_encode key ss))

let create_credentials sys request_date service =
  sys.Awsa_base.access_key_id ^ "/" ^ (credential_scope_value sys
                                         request_date
                                         service)
let base_uri = Uri.of_string ""

let add_token sys headers =
  match sys.Awsa_base.token with
  | Some token ->
    ("x-amz-security-token", token)::headers
  | None ->
    headers

let v4_authorize sys ?region service httpMethod uri
    raw_headers body =
  let open Deferred.Result.Monad_infix in
  Awsa_creds.resolve ?region sys
  >>= fun (sys', creds) ->
  let resolved_uri = Uri.resolve "http" base_uri uri in
  let (request_date, raw_headers, norm_headers) =
    Awsa_headers.process uri @@ add_token creds raw_headers in
  let (signed_headers, signature) = sign_request creds request_date
      service httpMethod
      resolved_uri
      norm_headers
      body in
  let credentials = create_credentials creds request_date service in
  return @@ Ok (sys',
                (List.append raw_headers
                   [("Authorization",
                     Awsa_sign.algo ^ " Credential=" ^ credentials ^
                     ", SignedHeaders=" ^ signed_headers ^
                     ", Signature=" ^ signature)]))

let t_of_credentials access_key_id secret_access_key default_region =
  Awsa_base.Creds {Awsa_base.secret_access_key = secret_access_key;
                   access_key_id = access_key_id;
                   token = None;
                   region = default_region}

let t_of_role ?region role_name =
  let open Deferred.Result.Monad_infix in
  let base = Awsa_base.Role {Awsa_base.name = role_name;
                             creds=None;
                             expires = Unix.gmtime 0.0} in
  Awsa_creds.resolve ?region base
  >>= fun (t, _) ->
  return @@ Ok t
