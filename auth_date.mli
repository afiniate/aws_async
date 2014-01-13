(** gets the current time as a time value *)
val now: unit -> Core.Std.Unix.tm

(** takes a string representing time as an ISO8601 date (Mon, 09 Sep
    2011 23:36:00 GMT) and converts it to a time value *)
val of_string: string -> Core.Std.Unix.tm

(** takes a unix time value and converts it to an ISO8601 date (Mon,
    09 Sep 2011 23:36:00 GMT) *)
val to_string: Core.Std.Unix.tm -> string

(** Takes a value and converts it to an ISO8601 basic format
    (20110909T233600Z) *)
val of_basic_string: string -> Core.Std.Unix.tm

(** Takes a unix time and outputs an ISO8601 basic format (20110909T233600Z) *)
val to_basic_string: Core.Std.Unix.tm -> string

(** Takes a unix time and outputs the year form of ISO8601 basic
    format (20110909) *)
val to_year_form_string: Core.Std.Unix.tm -> string
