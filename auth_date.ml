open Core.Std

let now () =
  Unix.gmtime (Unix.time ())

let of_string str =
    Unix.strptime ~fmt:"%a, %d %b %Y %H:%M:%S GMT" str

let to_string tm =
  Unix.strftime tm "%a, %d %b %Y %H:%M:%S GMT"

let of_basic_string str =
  Unix.strptime ~fmt:"%Y%m%dT%H%M%SZ" str

let to_basic_string tm =
  Unix.strftime tm "%Y%m%dT%H%M%SZ"

let to_year_form_string tm =
  Unix.strftime tm "%Y%m%d"
