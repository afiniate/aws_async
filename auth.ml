open Core.Std
open Auth_s

type t = S.t
type headers = Auth_headers.t

let credential_scope_value sys request_date region service =
  let date = Auth_date.to_year_form_string request_date in
  date ^ "/" ^ region ^ "/" ^ service ^ "/aws4_request"

let signing_key sys request_date region service =
  let date = Auth_date.to_year_form_string request_date in
  let ksecret = sys.S.secret_access_key in
  let kdate = Sign.sign ("AWS4" ^ ksecret) date in
  let kregion = Sign.sign kdate region in
  let kservice = Sign.sign kregion service in
  Sign.sign kservice "aws4_request"

let string_to_sign sys request_date region service httpMethod uri headers body =
  let (signed_headers, request_sig) =
    Auth_cn_req.signature httpMethod uri headers body in
  let date = Auth_date.to_basic_string request_date in
  (signed_headers, Sign.algo ^ "\n" ^
                     date ^ "\n" ^
                       (credential_scope_value
                          sys request_date region service) ^ "\n" ^
                         request_sig)

let sign_request sys request_date region service
                 httpMethod uri headers body =
  let (signed_headers, ss) = string_to_sign sys request_date region service
                                            httpMethod uri headers body in
  let key = signing_key sys request_date region service in
  (signed_headers, (Sign.sign_encode key ss))

let create_credentials sys request_date region service =
  sys.S.access_key_id ^ "/" ^ (credential_scope_value sys
                                                      request_date
                                                      region
                                                      service)
let base_uri = Uri.of_string ""

let v4_authorize sys ?(region = None) service httpMethod uri
                 raw_headers body =
  let resolved_uri = Uri.resolve "http" base_uri uri in
  let (request_date, raw_headers, norm_headers) =
    Auth_headers.process uri raw_headers in
  let reg = match region with
    | Some r -> r
    | None  -> sys.S.default_region in
  let (signed_headers, signature) = sign_request sys request_date reg
                                                 service httpMethod
                                                 resolved_uri
                                                 norm_headers
                                                 body in
  let credentials = create_credentials sys request_date reg service in
  List.append raw_headers
              [("Authorization",
                Sign.algo ^ " Credential=" ^ credentials ^
                  ", SignedHeaders=" ^ signed_headers ^
                    ", Signature=" ^ signature)]

let create access_key_id secret_access_key default_region =
  {S.secret_access_key = secret_access_key;
   access_key_id = access_key_id;
   default_region = default_region}
