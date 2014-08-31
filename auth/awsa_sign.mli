open Core.Std

(**
 * Use a sha256 hash algorithm to provide a simple hash of the string. Return
 * that hash as a hex encoded value
 *)
val hash: String.t -> String.t

(**
 * The amazon centric algorithm name used for signing
 *)
val algo: String.t

(**
 * provide a message digest for the second argument using the key
 * provided in the first
 *)
val sign: String.t -> String.t -> String.t

(**
 * Sign the string the same as in the `sign` function but hex encode
 * the result
 *)
val sign_encode: String.t -> String.t -> String.t
