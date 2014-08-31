open Core.Std
open Cryptokit

let algo = "AWS4-HMAC-SHA256"

let hex_encode x =
  let nibble x =
    char_of_int (if x < 10
                 then int_of_char '0' + x
                 else int_of_char 'a' + (x - 10)) in
  let result = String.make (String.length x * 2) ' ' in
  for i = 0 to String.length x - 1 do
    let byte = int_of_char x.[i] in
    result.[i * 2 + 0] <- nibble((byte lsr 4) land 15);
    result.[i * 2 + 1] <- nibble((byte lsr 0) land 15);
  done;
  result

let hash value =
  let hasher = Hash.sha256 () in
  hasher#add_string value;
  hex_encode hasher#result

let sign key value =
  let hash_fun = MAC.hmac_sha256 key in
  hash_string hash_fun value

let sys_sign sys body =
  let hashed_body = sign sys.Awsa_base.secret_access_key body in
  hex_encode hashed_body

let sign_encode key value =
  hex_encode (sign key value)
