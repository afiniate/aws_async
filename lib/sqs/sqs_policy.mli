open Core.Std
open Async.Std

val string_equals: Sqs_policy_t.key -> String.t List.t -> Sqs_policy_t.condition
val string_not_equals: Sqs_policy_t.key -> String.t List.t -> Sqs_policy_t.condition
val string_equals_ignore_case: Sqs_policy_t.key -> String.t List.t -> Sqs_policy_t.condition
val string_not_equals_ignore_case: Sqs_policy_t.key -> String.t List.t -> Sqs_policy_t.condition
val string_like: Sqs_policy_t.key -> String.t List.t -> Sqs_policy_t.condition
val string_not_like: Sqs_policy_t.key -> String.t List.t -> Sqs_policy_t.condition

val float_equals: Sqs_policy_t.key -> Float.t List.t -> Sqs_policy_t.condition
val float_not_equals: Sqs_policy_t.key -> Float.t List.t -> Sqs_policy_t.condition
val float_less_than: Sqs_policy_t.key -> Float.t List.t -> Sqs_policy_t.condition
val float_less_than_equals: Sqs_policy_t.key -> Float.t List.t -> Sqs_policy_t.condition
val float_greater_than: Sqs_policy_t.key -> Float.t List.t -> Sqs_policy_t.condition
val float_greater_than_equals: Sqs_policy_t.key -> Float.t List.t -> Sqs_policy_t.condition

val int_equals: Sqs_policy_t.key -> Int.t List.t -> Sqs_policy_t.condition
val int_not_equals: Sqs_policy_t.key -> Int.t List.t -> Sqs_policy_t.condition
val int_less_than: Sqs_policy_t.key -> Int.t List.t -> Sqs_policy_t.condition
val int_less_than_equals: Sqs_policy_t.key -> Int.t List.t -> Sqs_policy_t.condition
val int_greater_than: Sqs_policy_t.key -> Int.t List.t -> Sqs_policy_t.condition
val int_greater_than_equals: Sqs_policy_t.key -> Int.t List.t -> Sqs_policy_t.condition

val date_equals: Sqs_policy_t.key -> Time.t List.t -> Sqs_policy_t.condition
val date_not_equals: Sqs_policy_t.key -> Time.t List.t -> Sqs_policy_t.condition
val date_less_than: Sqs_policy_t.key -> Time.t List.t -> Sqs_policy_t.condition
val date_less_than_equals: Sqs_policy_t.key -> Time.t List.t -> Sqs_policy_t.condition
val date_greater_than: Sqs_policy_t.key -> Time.t List.t -> Sqs_policy_t.condition
val date_greater_than_equals: Sqs_policy_t.key -> Time.t List.t -> Sqs_policy_t.condition

val bool: Sqs_policy_t.key -> Bool.t List.t -> Sqs_policy_t.condition

val ip_address: Sqs_policy_t.key -> String.t List.t -> Sqs_policy_t.condition
val not_ip_address: Sqs_policy_t.key -> String.t List.t -> Sqs_policy_t.condition

val arn_equals: Sqs_policy_t.key -> String.t List.t -> Sqs_policy_t.condition
val arn_not_equals: Sqs_policy_t.key -> String.t List.t -> Sqs_policy_t.condition
val arn_like: Sqs_policy_t.key -> String.t List.t -> Sqs_policy_t.condition
val arn_not_like: Sqs_policy_t.key -> String.t List.t -> Sqs_policy_t.condition

val null: Sqs_policy_t.key -> Bool.t List.t -> Sqs_policy_t.condition
