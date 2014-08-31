open Core.Std
open Result.Monad_infix

type peek =
  | Start of String.t
  | End

let do_if_tag channel ~name succ fl =
  match Xmlm.peek channel with
  | `El_start ((_, local_name), _) when name = local_name ->
     succ channel
  | `El_start ((_, local_name), _)->
     fl channel
  | `El_end ->
     fl channel
  | `Data data ->
     fl channel
  | `Dtd _ ->
     fl channel

let extract_body channel =
  match Xmlm.peek channel with
  | `El_start ((_, local_name), _)->
     Result.fail (Sqs_system.Error
                    ((Sqs_system.Unexpected_xml_element local_name),
                     "Unexpected xml element in result"))
  | `El_end ->
     Ok (channel, "")
  | `Data data ->
     let _ = Xmlm.input channel in
     Ok (channel, data)
  | `Dtd _ ->
     Result.fail (Sqs_system.Error
                    (Sqs_system.Unexpected_dtd,
                     "Unexpected dtd element in result"))

let expect_tag channel ~name =
  match Xmlm.input channel with
  | `El_start ((_, local_name), _) when name = local_name ->
     Ok channel
  | `El_start ((_, local_name), _)->
     Result.fail (Sqs_system.Error
                    ((Sqs_system.Unexpected_xml_element local_name),
                     "Unexpected xml element in result"))
  | `El_end ->
     Result.fail (Sqs_system.Error
                    (Sqs_system.Unexpected_xml_end_element,
                     "Unexpected xml end element in result"))
  | `Data data -> Result.fail (Sqs_system.Error
                                 ((Sqs_system.Unexpected_xml_data_element data),
                                  "Unexpected data element in result"))
  | `Dtd _ -> Ok channel

let expect_dtd channel =
  match Xmlm.input channel with
  | `El_start ((_, name), _) ->
     Result.fail (Sqs_system.Error
                    ((Sqs_system.Unexpected_xml_element name),
                     "Unexpected xml element in result"))
  | `El_end ->
     Result.fail (Sqs_system.Error
                    (Sqs_system.Unexpected_xml_end_element,
                     "Unexpected xml end element in result"))
  | `Data data -> Result.fail (Sqs_system.Error
                                 ((Sqs_system.Unexpected_xml_data_element data),
                                  "Unexpected data element in result"))
  | `Dtd _ -> Ok channel

let expect_end channel =
  match Xmlm.input channel with
  | `El_start ((_, name), _) ->
     Result.fail (Sqs_system.Error
                    ((Sqs_system.Unexpected_xml_element name),
                     "Unexpected xml element in result"))
  | `El_end ->
     Ok channel
  | `Data data ->
     Result.fail (Sqs_system.Error
                    ((Sqs_system.Unexpected_xml_data_element data),
                     "Unexpected data element in result"))
  | `Dtd _ ->
     Result.fail (Sqs_system.Error
                    (Sqs_system.Unexpected_dtd,
                     "Unexpected dtd element in result"))


let extract_tag channel =
  match Xmlm.input channel with
  | `El_start ((_, local_name), _) ->
     Ok (channel, local_name)
  | `El_end ->
     Result.fail (Sqs_system.Error
                    (Sqs_system.Unexpected_xml_end_element,
                     "Unexpected xml end element in result"))
  | `Data data -> Result.fail (Sqs_system.Error
                                 ((Sqs_system.Unexpected_xml_data_element data),
                                  "Unexpected data element in result"))
  | `Dtd _ ->
     Result.fail (Sqs_system.Error
                    (Sqs_system.Unexpected_dtd,
                     "Unexpected dtd element in result"))


let peek_type channel =
  match Xmlm.peek channel with
  | `El_start ((_, local_name), _) ->
     Ok (channel, Start local_name)
  | `El_end ->
     Ok (channel, End)
  | `Data data ->
     Result.fail (Sqs_system.Error
                    ((Sqs_system.Unexpected_xml_data_element data),
                     "Unexpected data element in result"))
  | `Dtd _ ->
     Result.fail (Sqs_system.Error
                    (Sqs_system.Unexpected_dtd,
                     "Unexpected dtd element in result"))

let extract_tag_body channel ~name =
  expect_tag channel ~name
  >>= extract_body
  >>= fun (channel, body) ->
  expect_end channel
  >>= fun channel ->
  Ok (channel, body)

let expect_data channel =
  match Xmlm.input channel with
  | `El_start ((_, name), _) ->
     Result.fail (Sqs_system.Error
                    ((Sqs_system.Unexpected_xml_element name),
                     "Unexpected xml element in result"))
  | `El_end ->
     Result.fail (Sqs_system.Error
                    (Sqs_system.Unexpected_xml_end_element,
                     "Unexpected xml end element in result"))

  | `Data data ->
     Ok channel
  | `Dtd _ ->
     Result.fail (Sqs_system.Error
                    (Sqs_system.Unexpected_dtd,
                     "Unexpected dtd element in result"))
