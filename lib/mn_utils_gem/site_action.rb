require 'gelf'
require 'aws-sdk-cloudwatch'
require 'request_store'
require 'singleton'

# SiteAction class to log important site actions to Graylog
# and send a matching metric to Cloudwatch
#
# usage: MnUtils::SiteAction.instance.log(message, site_action, optional_payload)
#
#    eg: MnUtils::SiteAction.instance.log(
#           "Login attempted with non-existent email",
#           :login_attempt_nonexistent_email,
#           {_email: "fish@banana.com", _request_ip: "123.123.123.123"}
#        )
#        This logs all the details in Graylog and records a count of 1
#        against a Cloudwatch metric called login_attempt_nonexistent_email in namespace mn/auth
#
# The optional payload should be a simple flat hash with all keys starting
# with an underscore _ and all values being strings

module MnUtils
  class SiteAction

    include Singleton

    def initialize
      # add new site actions here under the relevant group
      # NO DUPLICATES please - a site action can only exist under one group
      @_site_actions_and_groups = {
          test: [
              :test_event_1,
              :test_event_2
          ],
          reg: [
              :reg_success_via_email,
              :reg_success_via_google,
              :reg_success_via_facebook,
              :reg_attempt_invalid_email,
              :reg_attempt_invalid_password,
              :reg_attempt_invalid_username,
          ],
          auth: [
              :login_success_via_email,
              :login_success_via_google,
              :login_success_via_facebook,
              :login_attempt_invalid_email,
              :login_attempt_nonexistent_email,
              :login_attempt_invalid_password,
              :login_attempt_incorrect_password,
          ],
      }.freeze

      # this creates a reverse map of all site actions and their corresponding group
      # for quick lookups by the code
      @_site_action_group_map = Hash[*(@_site_actions_and_groups.map {|k,v| v.map {|x| [x, k]}}.flatten)].freeze
    end

    def log(message, site_action, payload = {})

      # validate the parameters
      raise ArgumentError, 'message cannot be blank' \
        if message.blank?
      raise ArgumentError, 'site_action must be a symbol' \
        unless site_action.is_a?(Symbol)
      raise ArgumentError, 'payload must be a hash' \
        unless payload.is_a?(Hash)
      raise ArgumentError, 'site_action value is not in allowed list' \
        unless @_site_action_group_map.key? site_action

      # validate the payload hash
      payload.each do |key, value|
        raise ArgumentError, "payload key #{key} must be a symbol" \
          unless key.is_a?(Symbol)
        key_string = key.to_s
        raise ArgumentError, "payload key #{key} must begin with an underscore" \
          unless key_string.chars.first == '_'
        raise ArgumentError, "payload key #{key} must be at least 2 characters long" \
          unless key_string.length >= 2
        raise ArgumentError, "payload key cannot be _id" \
          if key_string == '_id'
        raise ArgumentError, "payload value for key #{key} must be a string" \
          unless value.is_a?(String)
      end

      # validate the environment variables we need
      raise ArgumentError, "ENV['SRV_CODE'] cannot be blank" \
        if ENV.key? 'SRV_CODE'

      # setup the full payload
      full_payload = payload.dup
      full_payload[:short_message] = message
      full_payload[:_site_action_group] = @_site_action_group_map[site_action]
      full_payload[:_site_action] = site_action
      full_payload[:_srv_code] = ENV['SRV_CODE']

      # add the request ID if available
      if RequestStore.store[:request_id]
        full_payload[:_request_id] = RequestStore.store[:request_id]
      end

      # send it off
      send_to_graylog full_payload
      send_to_cloudwatch full_payload
    end
  end

  private

  def send_to_graylog(payload)
    if ENV.key?('GRAYLOG_GELF_UDP_HOST') && ENV.key?('GRAYLOG_GELF_UDP_PORT')
      n = GELF::Notifier.new(ENV['GRAYLOG_GELF_UDP_HOST'], ENV['GRAYLOG_GELF_UDP_PORT'])
      n.notify! payload
    else
      Rails.logger.debug("Payload for Graylog: #{payload}")
    end
  rescue Exception => e
    Rails.logger.error e
  end

  def send_to_cloudwatch(payload)
    metric_name = payload[:_site_action]
    metric_data = [{
        metric_name: metric_name,
        value: 1,
        unit: "Count"
    }]
    if ENV.key?'CLOUDWATCH_ROOT_NAMESPACE'
      root_namespace = ENV['CLOUDWATCH_ROOT_NAMESPACE']
      second_namespace = payload[:_site_action_group]
      namespace = "#{root_namespace}/#{second_namespace}"
      cw = Aws::CloudWatch::Client.new
      cw.put_metric_data({
          namespace: namespace,
          metric_data: metric_data
      })
    else
      Rails.logger.debug("Payload for Cloudwatch #{metric_data}")
    end
  rescue Exception => e
    Rails.logger.error e
  end

end