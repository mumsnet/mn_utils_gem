require 'gelf'
require 'aws-sdk-cloudwatch'
require 'request_store'
require 'singleton'

# SiteAction class to log important site actions to Graylog
# and send a matching metric to Cloudwatch
#
# usage: MnUtilsLogging::SiteAction.instance.log(message, site_action, optional_payload)
#
#    eg: MnUtilsLogging::SiteAction.instance.log(
#           "Login attempted with non-existent email",
#           :login_attempt_nonexistent_email,
#           {_email: "fish@banana.com", _request_ip: "123.123.123.123"}
#        )
#        This logs all the details in Graylog and records a count of 1
#        against a Cloudwatch metric called login_attempt_nonexistent_email in namespace mn/auth
#
# The optional payload should be a simple flat hash with all keys starting
# with an underscore _ and all values being strings

module MnUtilsLogging
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
              :reg_conf_link_email_success,
              :reg_conf_link_email_fail,
              :reg_welcome_email_success,
              :reg_welcome_email_fail,
              :reg_conf_remind_email_success,
              :reg_conf_remind_email_fail,
              :bn_reg_email_success,
              :bn_reg_email_fail,
              :insight_welcome_email_success,
              :insight_welcome_email_fail
          ],
          auth: [
              :login_success_via_email,
              :login_success_via_google,
              :login_success_via_facebook,
              :login_attempt_invalid_email,
              :login_attempt_nonexistent_email,
              :login_attempt_invalid_password,
              :login_attempt_incorrect_password
          ],
          account: [
              :email_change_conf_link_email_success,
              :email_change_conf_link_email_fail,
              :pwd_reset_link_email_success,
              :pwd_reset_link_email_fail,
              :dereg_rqst_email_success,
              :dereg_rqst_email_fail
          ],
          pm: [
              :pm_notif_email_success,
              :pm_notif_email_fail
          ],
          talk: [
              :watch_thread_notif_email_success,
              :watch_thread_notif_email_fail,
              :media_rqst_welcome_email_success,
              :media_rqst_welcome_email_fail,
              :mention_notif_email_success,
              :mention_notif_email_fail
          ],
          admin: [
              :admin_email_success,
              :admin_email_fail,
          ],
          misc: [
              :unknown_email_success,
              :unknown_email_fail
          ]
      }.freeze

      # check for duplicates, and throw a tantrum if any are found
      tmp_map = {}
      @_site_actions_and_groups.each do |k, arr|
        arr.each do |v|
          raise ArgumentError, "Site action #{v} is declared more than once" \
              if tmp_map.key? v
          tmp_map[v] = true
        end
      end

      # create a reverse map of all site actions and their corresponding group
      # for quick lookups by the code
      @_site_action_group_map = Hash[*(@_site_actions_and_groups.map {|k, arr| arr.map {|v| [v, k]}}.flatten)].freeze
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

      # validate required environment variables if we are in production
      if ENV.key?( 'CLOUDWATCH_ROOT_NAMESPACE') \
          || ENV.key?('GRAYLOG_GELF_UDP_HOST') \
          || ENV.key?('GRAYLOG_GELF_UDP_PORT')
        raise ArgumentError, "ENV['CLOUDWATCH_ROOT_NAMESPACE'] is required" \
          unless ENV.key? 'CLOUDWATCH_ROOT_NAMESPACE'
        raise ArgumentError, "ENV['GRAYLOG_GELF_UDP_HOST'] is required" \
          unless ENV.key? 'GRAYLOG_GELF_UDP_HOST'
        raise ArgumentError, "ENV['GRAYLOG_GELF_UDP_PORT'] is required" \
          unless ENV.key? 'GRAYLOG_GELF_UDP_PORT'
        raise ArgumentError, "ENV['SITE_HOSTNAME'] is required" \
          unless ENV.key? 'SITE_HOSTNAME'
        raise ArgumentError, "ENV['SRV_CODE'] is required" \
          unless ENV.key? 'SRV_CODE'
      end

      # setup the full payload
      full_payload = payload.dup
      full_payload[:short_message] = message
      full_payload[:_site_action_group] = @_site_action_group_map[site_action]
      full_payload[:_site_action] = site_action

      # add other data to the payload if available
      full_payload[:_srv_code] = ENV['SRV_CODE'] if ENV.key? 'SRV_CODE'
      full_payload[:_site_hostname] = ENV['SITE_HOSTNAME'] if ENV.key? 'SITE_HOSTNAME'
      full_payload[:_request_id] = RequestStore.store[:request_id] if RequestStore.store[:request_id]
      full_payload[:_remote_ip] = RequestStore.store[:remote_ip] if RequestStore.store[:remote_ip]

      # send it off
      send_to_graylog full_payload
      send_to_cloudwatch full_payload
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
      cloudwatch_payload = {
          namespace: "mn/test",
          metric_data: [{
              metric_name: payload[:_site_action],
              dimensions: [{
                  name: "site_hostname",
                  value: "localhost"
              }],
              value: 1,
              unit: "Count"
          }]
      }
      if ENV.key? ('CLOUDWATCH_ROOT_NAMESPACE')
        root_namespace = ENV['CLOUDWATCH_ROOT_NAMESPACE']
        second_namespace = payload[:_site_action_group]
        cloudwatch_payload[:namespace] = "#{root_namespace}/#{second_namespace}"
        cloudwatch_payload[:metric_data][0][:dimensions][0][:value] = payload[:_site_hostname]
        cw = Aws::CloudWatch::Client.new
        cw.put_metric_data(cloudwatch_payload)
      else
        Rails.logger.debug("Payload for Cloudwatch: #{cloudwatch_payload}")
      end
    rescue Exception => e
      Rails.logger.error e
    end

  end # of class SiteAction

end # of module MnUtilsLogging
