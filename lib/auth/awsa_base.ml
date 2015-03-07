open Core.Std

type creds = {secret_access_key: string;
              access_key_id: string;
              token: String.t Option.t;
              region: string}

type error_code =
  | Uninstantiable_creds with sexp

exception Error of error_code * String.t  with sexp

let sexp_of_creds creds =
  Sexp.Atom "<hidden_credential_values>"

let creds_of_sexp _ =
  raise (Error (Uninstantiable_creds, "Credentials may not be instantiated"))

type role = {name: String.t; creds: creds Option.t; expires: Unix.tm} with sexp

type t =
  | Role of role
  | Creds of creds with sexp
