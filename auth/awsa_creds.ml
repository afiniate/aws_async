open Core.Std
open Async.Std
open Async_unix.Std
open Deferred.Result.Monad_infix


let resolve_creds region creds =
  match region with
  | Some resolved_region ->
     {creds with Awsa_base.region = resolved_region}
  | None ->
     creds


let tm_of_expiration =
  Awsa_date.of_iso8601_string

let convert_to_cred region old new_desc =
  let {Ec2im_iam_role_t.access_key_id;
       secret_access_key;
       token;
       expiration} = new_desc in
  (match old.Awsa_base.creds with
   | Some old_creds ->
      return @@ Ok {old_creds with
                     Awsa_base.access_key_id=access_key_id;
                     secret_access_key;
                     token = Some token}
   | None ->
     Ec2_inst_meta.get_region ()
     >>= fun resolved_region ->
     return @@ Ok {Awsa_base.access_key_id=access_key_id;
                    secret_access_key;
                    token = Some token;
                    region=resolved_region})
  >>= fun new_creds ->
  match region with
  | Some resolved_region ->
     return @@ Ok (Awsa_base.Role {old with
                                    Awsa_base.creds=Some new_creds;
                                    expires = tm_of_expiration expiration},
                   {new_creds with region=resolved_region})
  | None ->
     return @@ Ok (Awsa_base.Role {old with
                                    Awsa_base.creds=Some new_creds;
                                    expires = tm_of_expiration expiration},
                   new_creds)

let resolve_role (region: String.t Option.t) role =
  let now = Awsa_date.now () in
  match role.Awsa_base.creds with
  | Some creds ->
     if role.Awsa_base.expires > now then
       return @@ Ok (Awsa_base.Role role, resolve_creds region creds)
     else
       (Ec2_inst_meta.get_role role.Awsa_base.name
        >>= convert_to_cred region role)
  | None ->
     (Ec2_inst_meta.get_role role.Awsa_base.name
      >>= convert_to_cred region role)

let resolve ?region = function
  | Awsa_base.Creds creds ->
     return @@ Ok (Awsa_base.Creds creds, resolve_creds region creds)
  | Awsa_base.Role role ->
    resolve_role region role
