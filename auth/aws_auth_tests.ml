open OUnit2
open Core.Std
open Async.Std
open Deferred.Result

let service = "host"

let sys = Aws.Auth.t_of_credentials "AKIDEXAMPLE"
    "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY"
    "us-east-1"

let get_header_key_duplicate _ =
  let headers = [("DATE", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("host", "host.foo.com");
                 ("ZOO", "zoobar");
                 ("zoo", "foobar");
                 ("zoo", "zoobar")] in
  let uri = Uri.of_string "http://host.foo.com/" in
  Aws.Auth.v4_authorize sys service "POST" uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("DATE", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("host", "host.foo.com");
                ("ZOO", "zoobar");
                ("zoo", "foobar");
                ("zoo", "zoobar");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host;zoo, Signature=54afcaaf45b331f81cd2edb974f7b824ff4dd594cbbaa945ed636b48477368ed")]
    authorized_headers;
  return ()

let get_header_value_order _ =
  let headers = [("DATE", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("host", "host.foo.com");
                 ("p", "z");
                 ("p", "a");
                 ("p", "p");
                 ("p", "a")] in
  let uri = Uri.of_string "http://host.foo.com/" in
  Aws.Auth.v4_authorize sys service "POST" uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("DATE", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("host", "host.foo.com");
                ("p", "z");
                ("p", "a");
                ("p", "p");
                ("p", "a");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host;p, Signature=d2973954263943b11624a11d1c963ca81fb274169c7868b2858c04f083199e3d")]
    authorized_headers;
  return ()

let get_header_value_trim _ =
  let headers = [("DATE", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("host", "host.foo.com");
                 ("p", "phfft ")] in
  let uri = Uri.of_string "http://host.foo.com/" in
  Aws.Auth.v4_authorize sys service "POST" uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("DATE", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("host", "host.foo.com");
                ("p", "phfft ");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host;p, Signature=debf546796015d6f6ded8626f5ce98597c33b47b9164cf6b17b4642036fcb592")]
    authorized_headers;
  return ()

let get_relative_relative _ =
  let headers = [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("Host", "host.foo.com")] in
  let uri = Uri.of_string "http://host.foo.com/foo/bar/../.." in
  Aws.Auth.v4_authorize sys service "GET" uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("Host", "host.foo.com");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=b27ccfbfa7df52a200ff74193ca6e32d4b48b8856fab7ebf1c595d0670a7e470")]
    authorized_headers;
  return ()

let get_relative _ =
  let headers = [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("Host", "host.foo.com")] in
  let uri = Uri.of_string "http://host.foo.com/foo/.." in
  Aws.Auth.v4_authorize sys service "GET" uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("Host", "host.foo.com");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=b27ccfbfa7df52a200ff74193ca6e32d4b48b8856fab7ebf1c595d0670a7e470")]
    authorized_headers;
  return ()

let slash_dot_slash _ =
  let headers = [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("Host", "host.foo.com")] in
  let uri = Uri.of_string "http://host.foo.com/./" in
  Aws.Auth.v4_authorize sys service "GET" uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("Host", "host.foo.com");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=b27ccfbfa7df52a200ff74193ca6e32d4b48b8856fab7ebf1c595d0670a7e470")]
    authorized_headers;
  return ()

let slash_pointless_dot _ =
  let headers = [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("Host", "host.foo.com")] in
  let uri = Uri.of_string "http://host.foo.com/./foo" in
  Aws.Auth.v4_authorize sys service "GET" uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("Host", "host.foo.com");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=910e4d6c9abafaf87898e1eb4c929135782ea25bb0279703146455745391e63a")]
    authorized_headers;
  return ()

let slash _ =
  let headers = [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("Host", "host.foo.com")] in
  let uri = Uri.of_string "http://host.foo.com//" in
  Aws.Auth.v4_authorize sys service "GET" uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("Host", "host.foo.com");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=b27ccfbfa7df52a200ff74193ca6e32d4b48b8856fab7ebf1c595d0670a7e470")]
    authorized_headers;
  return ()

let slashes _ =
  let headers = [("date", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("host", "host.foo.com")] in
  let uri = Uri.of_string "http://host.foo.com/foo/" in
  Aws.Auth.v4_authorize sys service "GET" uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("date", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("host", "host.foo.com");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=b00392262853cfe3201e47ccf945601079e9b8a7f51ee4c3d9ee4f187aa9bf19")]
    authorized_headers;
  return ()

let space _ =
  let headers = [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("Host", "host.foo.com")] in
  let uri = Uri.of_string "http://host.foo.com/ /foo" in
  Aws.Auth.v4_authorize sys service "GET" uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("Host", "host.foo.com");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=f309cfbd10197a230c42dd17dbf5cca8a0722564cb40a872d25623cfa758e374")]
    authorized_headers;
  return ()

let unreserved _ =
  let headers = [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("Host", "host.foo.com")] in
  let uri = Uri.of_string "http://host.foo.com/-._~0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz" in
  Aws.Auth.v4_authorize sys service "GET"  uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("Host", "host.foo.com");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=830cc36d03f0f84e6ee4953fbe701c1c8b71a0372c63af9255aa364dd183281e")]
    authorized_headers;
  return ()

let utf8 _ =
  let headers = [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("Host", "host.foo.com")] in
  let uri = Uri.of_string "http://host.foo.com/%E1%88%B4" in
  Aws.Auth.v4_authorize sys service "GET" uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("Host", "host.foo.com");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=8d6634c189aa8c75c2e51e106b6b5121bed103fdb351f7d7d4381c738823af74")]
    authorized_headers;
  return ()

let vanilla_query_order_key_case _ =
  let headers = [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("Host", "host.foo.com")] in
  let uri = Uri.of_string "http://host.foo.com/?foo=Zoo&foo=aha" in
  Aws.Auth.v4_authorize sys service "GET" uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("Host", "host.foo.com");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=be7148d34ebccdc6423b19085378aa0bee970bdc61d144bd1a8c48c33079ab09")]
    authorized_headers;
  return ()

let vanilla_query_order_key _ =
  let headers = [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("Host", "host.foo.com")] in
  let uri = Uri.of_string "http://host.foo.com/?a=foo&b=foo" in
  Aws.Auth.v4_authorize sys service "GET" uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("Host", "host.foo.com");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=0dc122f3b28b831ab48ba65cb47300de53fbe91b577fe113edac383730254a3b")]
    authorized_headers;
  return ()

let vanilla_query_order_value _ =
  let headers = [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("Host", "host.foo.com")] in
  let uri = Uri.of_string "http://host.foo.com/?foo=b&foo=a" in
  Aws.Auth.v4_authorize sys service "GET" uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("Host", "host.foo.com");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=feb926e49e382bec75c9d7dcb2a1b6dc8aa50ca43c25d2bc51143768c0875acc")]
    authorized_headers;
  return ()

let vanilla_query_unreserved _ =
  let headers = [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("Host", "host.foo.com")] in
  let uri = Uri.of_string "http://host.foo.com/?-._~0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz=-._~0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz" in
  Aws.Auth.v4_authorize sys service "GET" uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("Host", "host.foo.com");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=f1498ddb4d6dae767d97c466fb92f1b59a2c71ca29ac954692663f9db03426fb")]
    authorized_headers;
  return ()

let vanilla_query _ =
  let headers = [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("Host", "host.foo.com")] in
  let uri = Uri.of_string "http://host.foo.com/" in
  Aws.Auth.v4_authorize sys service "GET" uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("Host", "host.foo.com");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=b27ccfbfa7df52a200ff74193ca6e32d4b48b8856fab7ebf1c595d0670a7e470")]
    authorized_headers;
  return ()

let vanilla_utf8_query _ =
  let headers = [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("Host", "host.foo.com")] in
  let uri = Uri.of_string "http://host.foo.com/?ሴ=bar" in
  Aws.Auth.v4_authorize sys service "GET"  uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("Host", "host.foo.com");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=6fb359e9a05394cc7074e0feb42573a2601abc0c869a953e8c5c12e4e01f1a8c")]
    authorized_headers;
  return ()

let vanilla_empty_query_key _ =
  let headers = [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("Host", "host.foo.com")] in
  let uri = Uri.of_string "http://host.foo.com/?foo=bar" in
  Aws.Auth.v4_authorize sys service "GET" uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("Host", "host.foo.com");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=56c054473fd260c13e4e7393eb203662195f5d4a1fada5314b8b52b23f985e9f")]
    authorized_headers;
  return ()

let vanilla _ =
  let headers = [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("Host", "host.foo.com")] in
  let uri = Uri.of_string "http://host.foo.com/" in
  Aws.Auth.v4_authorize sys service "GET" uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("Host", "host.foo.com");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=b27ccfbfa7df52a200ff74193ca6e32d4b48b8856fab7ebf1c595d0670a7e470")]
    authorized_headers;
  return ()

let post_header_key_case _ =
  let headers = [("DATE", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("host", "host.foo.com")] in
  let uri = Uri.of_string "http://host.foo.com" in
  Aws.Auth.v4_authorize sys service "POST" uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("DATE", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("host", "host.foo.com");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=22902d79e148b64e7571c3565769328423fe276eae4b26f83afceda9e767f726")]
    authorized_headers;
  return ()

let post_header_key_sort _ =
  let headers = [("DATE", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("host", "host.foo.com");
                 ("ZOO", "zoobar")] in
  let uri = Uri.of_string "http://host.foo.com" in
  Aws.Auth.v4_authorize sys service "POST" uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("DATE", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("host", "host.foo.com");
                ("ZOO", "zoobar");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host;zoo, Signature=b7a95a52518abbca0964a999a880429ab734f35ebbf1235bd79a5de87756dc4a")]
    authorized_headers;
  return ()

let post_header_value_case _ =
  let headers = [("DATE", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("host", "host.foo.com");
                 ("zoo", "ZOOBAR")] in
  let uri = Uri.of_string "http://host.foo.com" in
  Aws.Auth.v4_authorize sys service "POST" uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("DATE", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("host", "host.foo.com");
                ("zoo", "ZOOBAR");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host;zoo, Signature=273313af9d0c265c531e11db70bbd653f3ba074c1009239e8559d3987039cad7")]
    authorized_headers;
  return ()

let post_vanilla_empty_query_value _ =
  let headers = [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("Host", "host.foo.com")] in
  let uri = Uri.of_string "http://host.foo.com/?foo=bar" in
  Aws.Auth.v4_authorize sys service "POST" uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("Host", "host.foo.com");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=b6e3b79003ce0743a491606ba1035a804593b0efb1e20a11cba83f8c25a57a92")]
    authorized_headers;
  return ()

let post_vanilla_query_space _ =
  let headers = [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("Host", "host.foo.com")] in
  let uri = Uri.of_string "http://host.foo.com/?f oo=b ar" in
  Aws.Auth.v4_authorize sys service "POST" uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("Host", "host.foo.com");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=b7eb653abe5f846e7eee4d1dba33b15419dc424aaf215d49b1240732b10cc4ca")]
    authorized_headers;
  return ()

let post_vanilla_query _ =
  let headers = [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("Host", "host.foo.com")] in
  let uri = Uri.of_string "http://host.foo.com/?foo=bar" in
  Aws.Auth.v4_authorize sys service "POST" uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("Host", "host.foo.com");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=b6e3b79003ce0743a491606ba1035a804593b0efb1e20a11cba83f8c25a57a92")]
    authorized_headers;
  return ()

let post_vanilla _ =
  let headers = [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("Host", "host.foo.com")] in
  let uri = Uri.of_string "http://host.foo.com" in
  Aws.Auth.v4_authorize sys service "POST" uri headers ""
  >>= fun (sys', authorized_headers) ->
  assert_equal [("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("Host", "host.foo.com");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=date;host, Signature=22902d79e148b64e7571c3565769328423fe276eae4b26f83afceda9e767f726")]
    authorized_headers;
  return ()

let post_x_www_form_urlencoded_parameters _ =
  let headers = [("Content-Type",
                  "application/x-www-form-urlencoded; charset=utf8");
                 ("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("Host", "host.foo.com")] in
  let uri = Uri.of_string "http://host.foo.com" in
  Aws.Auth.v4_authorize sys service "POST" uri headers "foo=bar"
  >>= fun (sys', authorized_headers) ->
  assert_equal [("Content-Type",
                 "application/x-www-form-urlencoded; charset=utf8");
                ("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("Host", "host.foo.com");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=content-type;date;host, Signature=b105eb10c6d318d2294de9d49dd8b031b55e3c3fe139f2e637da70511e9e7b71")]
    authorized_headers;
  return ()

let post_x_www_form_urlencoded _ =
  let headers = [("Content-Type",
                  "application/x-www-form-urlencoded");
                 ("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                 ("Host", "host.foo.com")] in
  let uri = Uri.of_string "http://host.foo.com" in
  Aws.Auth.v4_authorize sys service "POST" uri headers "foo=bar"
  >>= fun (sys', authorized_headers) ->
  assert_equal [("Content-Type",
                 "application/x-www-form-urlencoded");
                ("Date", "Mon, 09 Sep 2011 23:36:00 GMT");
                ("Host", "host.foo.com");
                ("Authorization", "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20110909/us-east-1/host/aws4_request, SignedHeaders=content-type;date;host, Signature=5a15b22cf462f047318703b92e6f4f38884e4a7ab7b1d6426ca46a8bd1c26cbc")]
    authorized_headers;
  return ()

let tests = [("duplicate header keys", get_header_key_duplicate);
             ("header value order", get_header_value_order);
             ("header value trim", get_header_value_trim);
             ("relative uri", get_relative);
             ("double relative uris", get_relative_relative);
             ("slash dot slash", slash_dot_slash);
             ("slash pointless dot", slash_pointless_dot);
             ("slash", slash);
             ("slashes", slashes);
             ("space" , space);
             ("unreserved", unreserved);
             ("utf8", utf8);
             ("vanilla query order key case", vanilla_query_order_key_case);
             ("vanilla query order key", vanilla_query_order_key);
             ("vanilla query order value", vanilla_query_order_value);
             ("vanilla query unreserved", vanilla_query_unreserved);
             ("vanilla query", vanilla_query);
             ("vanilla utf8 query", vanilla_utf8_query);
             ("vanilla empty query key", vanilla_empty_query_key);
             ("vanilla", vanilla);
             ("post header key case", post_header_key_case);
             ("post header key sort", post_header_key_sort);
             ("post header value case", post_header_value_case);
             ("post vanilla empty query value", post_vanilla_empty_query_value);
             ("post vanilla query space", post_vanilla_query_space);
             ("post vanilla query", post_vanilla_query);
             ("post x www form urlencoded parameters", post_x_www_form_urlencoded_parameters);
             ("post x www form urlencoded", post_x_www_form_urlencoded)]
