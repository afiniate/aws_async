module Policy = Sqs_policy
module Create_queue = Sqs_createqueue
module Delete_queue = Sqs_deletequeue
module Get_queue_url = Sqs_getqueueurl
module Send_message = Sqs_sendmessage
module Receive_message = Sqs_receivemessage
module Delete_message = Sqs_deletemessage

include Sqs_system
