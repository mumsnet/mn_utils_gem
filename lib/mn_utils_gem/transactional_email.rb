require 'aws-sdk-sqs'
require 'request_store'
require 'singleton'

# TransactionalEmail class to send transactional emails
# via the mail service.
#
# usage: MnUtilsEmail::TransactionalEmail.instance.enqueue(
#           message_type:, to_address:, subject:, fallback_text:, template_fields: {}, cc_addresses: '')
#
#    eg: MnUtilsEmail::TransactionalEmail.instance.enqueue(
#           message_type: 'REGISTRATION_WELCOME',
#           to_address: 'joe@example.com',
#           subject: 'Welcome to Mumsnet',
#           fallback_text: "Dear joe\nWelcome to Mumsnet\nMNHQ"
#        )
#        This puts the message onto the correct SQS queue
#        which will then be picked up by the mail service and sent.

module MnUtilsEmail
  class TransactionalEmail

    include Singleton

    def enqueue(message_type:, to_address:, subject:, fallback_text:, template_fields: {}, cc_addresses: '')

      # validate the parameters
      raise ArgumentError, "message_type cannot be blank" \
          if message_type.blank?
      raise ArgumentError, "to_address cannot be blank" \
          if to_address.blank?
      raise ArgumentError, "subject cannot be blank" \
          if subject.blank?
      raise ArgumentError, "fallback_text cannot be blank" \
          if fallback_text.blank?
      raise ArgumentError, "to_address #{to_address} is not a valid email address" \
          unless to_address =~ /@/

      # validate environment variables that we need
      raise ArgumentError, "ENV['SQS_MAIL2_QUEUE_URL'] is required" \
          unless ENV.key? 'SQS_MAIL2_QUEUE_URL'

      # construct the message body for SQS
      message_body = {
          message_schema_version: 1,
          message_type: message_type,
          template_fields: template_fields.to_json,
          to_address: to_address,
          cc_addresses: cc_addresses,
          subject: subject,
          fallback_text: fallback_text
      }

      # put it on the SQS queue
      sqs = Aws::SQS::Client.new()
      sqs.send_message(
          queue_url: ENV['SQS_MAIL_QUEUE_URL'],
          message_body: message_body
      )

    end # of method enqueue

  end # of class TransactionalEmail

end # of module MnUtilsEmail
