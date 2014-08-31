open Core.Std

type creds = {secret_access_key: String.t;
              access_key_id: String.t;
              token: String.t Option.t;
              region: String.t}

val sexp_of_creds: creds -> Sexp.t
val creds_of_sexp: Sexp.t -> creds

type role = {name: String.t; creds: creds Option.t; expires: Unix.tm} with sexp

type t =
  | Role of role
  | Creds of creds with sexp

type error_code =
  | Uninstantiable_creds with sexp

exception Error of error_code * String.t  with sexp
