open Core.Std

type header = (String.t * String.t)
type t = header List.t

type quote_type = Single | Double

let rec run_to_end_quote quote_type value start len =
  if start < len
  then match (quote_type, value.[start]) with
    | (_, '\\') ->
      begin if start + 1 < len
        then match (quote_type, value.[start + 1]) with
          | (Single, '\'') ->
            run_to_end_quote quote_type value (start + 2) len
          | (Double, '\"') ->
            run_to_end_quote quote_type value (start + 2) len
          | _ ->
            run_to_end_quote quote_type value (start + 1) len
        else
          start
      end
    | (Single, '\'') ->
      start + 1
    | (Double, '"') ->
      start + 1
    | _ ->
      run_to_end_quote quote_type value (start + 1) len
  else
    start

let rec run_to_end_of_space value start len =
  if start < len
  then match value.[start] with
    | ' ' ->
      run_to_end_of_space value (start + 1) len
    | '\t' ->
      run_to_end_of_space value (start + 1) len
    | _ ->
      start
  else
    start

let rec blit value target target_off start e continue len =
  let chunk_len = (e - start) in
  String.blit value start target target_off chunk_len;
  find_next value target (target_off + chunk_len) continue continue len
and find_next value target target_off last current len =
  if current < len
  then match value.[current] with
    | '\'' ->
      let next_chunk = run_to_end_quote Single value (current + 1) len in
      find_next value target target_off last next_chunk len
    | '"' ->
      let next_chunk = run_to_end_quote Double value (current + 1) len in
      find_next value target target_off last next_chunk len
    | ' ' ->
      let next_current = run_to_end_of_space value (current + 1) len in
      blit value target target_off last (current + 1) next_current len
    | '\t' ->
      let next_current = run_to_end_of_space value (current + 1) len in
      blit value target target_off last (current + 1) next_current len
    | _ ->
      find_next value target target_off last (current + 1) len
  else
    let () = if (current - last) <> 0 then
        String.blit value last target target_off (current - last)
      else
        () in
    String.strip target

let trim_all value =
  let len = String.length value in
  let target = String.make len ' ' in
  find_next value target 0 0 0 len

let dedup headers =
  List.rev (List.fold_left headers ~init:[]
              ~f:(fun acc (k1, v1) ->
                  match List.Assoc.find acc k1 with
                  | Some v0 -> let acc' = List.Assoc.remove acc k1 in
                    (k1, v0 ^ "," ^ v1)::acc'
                  | None -> (k1, v1)::acc))

let sort =
  List.sort ~cmp:(fun (k1, v1) (k2, v2)->
      let res = String.compare k1 k2 in
      if res = 0
      then String.compare v1 v2
      else res)
let rec normalize_host req_date uri headers norm_headers =
  match List.Assoc.find norm_headers "host" with
  | Some _r -> (req_date, headers, sort norm_headers)
  | None ->
    (match Uri.host uri with
     | Some host -> (req_date,
                     headers,
                     sort (("host",  host)::norm_headers))
     | None -> (req_date, headers, sort norm_headers))
and process uri headers =
  let norm_headers =
    let manipulated_headers =
      (List.map headers
         ~f:(fun (k1, v1) ->
             (String.lowercase k1, trim_all v1))) in
    dedup (sort manipulated_headers) in
  let request_date = match List.Assoc.find norm_headers "date" with
    | Some d -> Awsa_date.of_string d
    | None -> Awsa_date.now () in
  match List.Assoc.find norm_headers "date" with
  | Some r -> normalize_host request_date uri headers  norm_headers
  | None -> let formated_date = Awsa_date.to_basic_string request_date in
    normalize_host request_date uri
      (("date", formated_date)::headers)
      (("date", formated_date)::norm_headers)

let print =
  List.iter ~f:(fun (k, v) ->
      print_string k;
      print_string ":";
      print_string v;
      print_newline ())
