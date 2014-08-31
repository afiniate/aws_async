open Core.Std

val counted_param: Uri.t ->
                   name:String.t ->
                   converter:('a -> String.t) ->
                   values:'a List.t Option.t ->
                   Uri.t

val add_list_param: Uri.t * Int.t ->
                    name:String.t ->
                    converter:('a -> String.t) ->
                    value:'a Option.t ->
                    Uri.t * Int.t

val add_param: Uri.t ->
               name:String.t ->
               converter:('a -> String.t) ->
               value:'a Option.t ->
               Uri.t

val add_standard_param: Uri.t ->
                        name:String.t ->
                        value:String.t ->
                        Uri.t

val convert_output: Uri.t -> Uri.t * Int.t

val parse_response_metadata: Xmlm.input -> (Xmlm.input * String.t, Exn.t) Result.t

val convert_string: String.t -> String.t

val encode_message_body: String.t -> String.t
val decode_message_body: String.t -> String.t

val time_of_epoch_milli_string: String.t -> Time.t
