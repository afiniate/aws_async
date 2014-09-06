open Core.Std

let http_request_method http_method =
  let encode_method = String.uppercase in
  encode_method http_method

let canonical_uri uri =
  match Uri.path uri with
  | "" -> "/"
  | "//" -> "/"
  | res -> res

let safe_chars =
  let a = Array.create 256 false in
  let always_safe =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.-~" in
  for i = 0 to String.length always_safe - 1 do
    let c = Caml.Char.code always_safe.[i] in
    a.(c) <- true
  done;
  a

let pct_encode value =
  let len = String.length value in
  let buf = Buffer.create (String.length value) in
  let rec scan start cur =
    if cur >= len
    then Buffer.add_substring buf value start (cur-start)
    else begin
      let c = Caml.Char.code value.[cur] in
      if safe_chars.(c)
      then scan start (cur+1)
      else begin
        if cur > start
        then Buffer.add_substring buf value start (cur-start);
        Buffer.add_string buf (Printf.sprintf "%%%02X" c);
        scan (cur+1) (cur+1)
      end
    end in
  scan 0 0;
  Buffer.contents buf

(**
 * creating a canonical query string is slightly more difficult
 * then the aws documentation suggests. Query strings need to be percent
 * encoded. In cases where there is a space in the key, the rest of the
 * param is discarded so the string `f oo=bar` gets turned into a
 * canonical representation of `f=` You can see that `oo=bar` is
 * discarded.
*)
let canonical_query_string uri =
  let rec whitespace_pos value idx len =
    (if idx < len
     then (match value.[idx] with
         | ' ' -> idx
         | '\t' -> idx
         | '\n' -> idx
         | _ -> whitespace_pos value (idx + 1) len)
     else len) in
  let normalize_value first rest =
    List.fold_left rest ~init:(pct_encode first)
      ~f:(fun acc el -> acc ^ "," ^ pct_encode el) in
  let stringify_query_parm (k1, v1) =
    let klen = (String.length k1) in
    let w_pos = whitespace_pos k1 0 klen in
    if w_pos < klen
    then String.sub k1 0 w_pos ^ "="
    else let ek1 = pct_encode k1 in
      match v1 with
      | [] -> ek1 ^ "="
      | [value] -> ek1 ^ "=" ^ pct_encode value
      | h::t -> k1 ^ "=" ^ (normalize_value h t) in
  let sorted = List.sort ~cmp:(fun (k1, v1)  (k2, v2) ->
      let res = String.compare k1 k2 in
      if res = 0
      then compare v1 v2
      else res)
      (Uri.query uri) in
  let normalized = List.map sorted ~f:stringify_query_parm in
  match normalized with
  | [] -> ""
  | h::t -> List.fold_left t ~init:h ~f:(fun acc el -> acc ^ "&" ^ el)

let signed_headers headers =
  match headers with
  | [] -> ""
  | (h, _)::t ->
    List.fold_left t
      ~init:h
      ~f:(fun acc (k1, _) ->
          acc ^ ";" ^ k1)

let canonical_headers uri headers =
  List.fold_left headers
    ~init:""
    ~f:(fun acc (k1, v1) ->
        acc ^ k1 ^ ":" ^ v1 ^ "\n")

let signature http_method uri headers body =
  let signed_headers = signed_headers headers in
  let request = ((http_request_method http_method) ^ "\n" ^
                 (canonical_uri uri) ^ "\n" ^
                 (canonical_query_string uri) ^ "\n" ^
                 (canonical_headers uri headers) ^ "\n" ^
                 signed_headers ^ "\n" ^
                 (Awsa_sign.hash body)) in
  (signed_headers, Awsa_sign.hash request)
