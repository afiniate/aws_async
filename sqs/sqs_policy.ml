open Core.Std
open Async.Std

let string_of_key =
  Sqs_policy_j.string_of_key

let string_of_conditional =
  Sqs_policy_j.string_of_conditional

let string_equals key values =
  [(string_of_conditional `String_equals,
    [(string_of_key key, values)])]

let string_not_equals key values =
  [(string_of_conditional `String_not_equals,
    [(string_of_key key, values)])]

let string_equals_ignore_case key values =
  [(string_of_conditional `String_equals_ignore_case, [(string_of_key key, values)])]

let string_not_equals_ignore_case key values =
  [(string_of_conditional `String_not_equals_ignore_case,
    [(string_of_key key, values)])]

let string_like key values =
  [(string_of_conditional `String_like,
    [(string_of_key key, values)])]

let string_not_like key values =
  [(string_of_conditional `String_not_like,
    [(string_of_key key, values)])]

let float_equals key values =
  let processed_values = List.map ~f:Float.to_string values in
  [(string_of_conditional `Numeric_equals,
    [(string_of_key key, processed_values)])]

let float_not_equals key values =
  let processed_values = List.map ~f:Float.to_string values in
  [(string_of_conditional `Numeric_not_equals,
    [(string_of_key key, processed_values)])]

let float_less_than key values =
  let processed_values = List.map ~f:Float.to_string values in
  [(string_of_conditional `Numeric_less_than,
    [(string_of_key key, processed_values)])]

let float_less_than_equals key values =
  let processed_values = List.map ~f:Float.to_string values in
  [(string_of_conditional `Numeric_less_than_equals,
    [(string_of_key key, processed_values)])]

let float_greater_than key values =
  let processed_values = List.map ~f:Float.to_string values in
  [(string_of_conditional `Numeric_greater_than,
    [(string_of_key key, processed_values)])]

let float_greater_than_equals key values =
  let processed_values = List.map ~f:Float.to_string values in
  [(string_of_conditional `Numeric_greater_than_equals,
    [(string_of_key key, processed_values)])]

let int_equals key values =
  let processed_values = List.map ~f:Int.to_string values in
  [(string_of_conditional `Numeric_equals,
    [(string_of_key key, processed_values)])]

let int_not_equals key values =
  let processed_values = List.map ~f:Int.to_string values in
  [(string_of_conditional `Numeric_not_equals,
    [(string_of_key key, processed_values)])]

let int_less_than key values =
  let processed_values = List.map ~f:Int.to_string values in
  [(string_of_conditional `Numeric_less_than,
    [(string_of_key key, processed_values)])]

let int_less_than_equals key values =
  let processed_values = List.map ~f:Int.to_string values in
  [(string_of_conditional `Numeric_less_than_equals,
    [(string_of_key key, processed_values)])]

let int_greater_than key values =
  let processed_values = List.map ~f:Int.to_string values in
  [(string_of_conditional `Numeric_greater_than,
    [(string_of_key key, processed_values)])]

let int_greater_than_equals key values =
  let processed_values = List.map ~f:Int.to_string values in
  [(string_of_conditional `Numeric_greater_than_equals,
    [(string_of_key key, processed_values)])]

let format_times =
  List.map ~f:(fun t -> Time.format t "%Y-%m-%dT%H:%M:%SZ")

let date_equals key values =
  let processed_values = format_times values in
  [(string_of_conditional `Date_equals,
    [(string_of_key key, processed_values)])]

let date_not_equals key values =
  let processed_values = format_times values in
  [(string_of_conditional `Date_not_equals,
    [(string_of_key key, processed_values)])]

let date_less_than key values =
  let processed_values = format_times values in
  [(string_of_conditional `Date_less_than,
    [(string_of_key key, processed_values)])]

let date_less_than_equals key values =
  let processed_values = format_times values in
  [(string_of_conditional `Date_less_than_equals,
    [(string_of_key key, processed_values)])]

let date_greater_than key values =
  let processed_values = format_times values in
  [(string_of_conditional `Date_less_than,
    [(string_of_key key, processed_values)])]

let date_greater_than_equals key values =
  let processed_values = format_times values in
  [(string_of_conditional `Date_less_than_equals,
    [(string_of_key key, processed_values)])]

let bool key values =
  let processed_values = List.map ~f:(function | true -> "true" | false -> "false")
      values in
  [(string_of_conditional `Bool,
    [(string_of_key key, processed_values)])]

let ip_address key values =
  [(string_of_conditional `Ip_address,
    [(string_of_key key, values)])]

let not_ip_address key values =
  [(string_of_conditional `Not_ip_address,
    [(string_of_key key, values)])]

let arn_equals key values =
  [(string_of_conditional `Arn_equals,
    [(string_of_key key, values)])]

let arn_not_equals key values =
  [(string_of_conditional `Arn_not_equals,
    [(string_of_key key, values)])]

let arn_like key values =
  [(string_of_conditional `Arn_like,
    [(string_of_key key, values)])]

let arn_not_like key values =
  [(string_of_conditional `Arn_not_like,
    [(string_of_key key, values)])]

let null key values =
  let processed_values = List.map ~f:(function | true -> "true" | false -> "false")
      values in
  [(string_of_conditional `Null,
    [(string_of_key key, processed_values)])]
