require 'gelf'
require 'request_store'

module MnUtils
  class Graylog

    ALLOWED_SITE_ACTION_GROUPS = [
        :authentication,
        :talk,
        :pm,
        :registration,
        :search,
        :food,
        :reviews,
        :profile,
        :admin
    ].freeze

    def log(message, site_action_group, site_action, payload = nil)

      # validate the parameters
      raise ArgumentError, 'message cannot be blank' \
        if message.blank?
      raise ArgumentError, 'site_action_group must be a symbol' \
        unless site_action_group.is_a?(Symbol)
      raise ArgumentError, 'site_action must be a symbol' \
        unless site_action.is_a?(Symbol)
      raise ArgumentError, 'payload must be a hash or nil' \
        unless (payload.nil? || payload.is_a?(Hash))
      raise ArgumentError, 'site_action_group value is not in allowed list' \
        unless ALLOWED_SITE_ACTION_GROUPS.include? site_action_group

      # validate the payload hash if provided
      if !payload.nil?
        payload.each do |key, value|
          raise ArgumentError, "payload key #{key} must be a symbol" \
            unless key.is_a?(Symbol)
          key_string = key.to_s
          raise ArgumentError, "payload key #{key} must begin with an underscore" \
            unless key_string.chars.first == '_'
          raise ArgumentError, "payload key #{key} must be at least 2 characters long" \
            unless key_string.length >= 2
          raise ArgumentError, "payload value for key #{key} must be a string" \
            unless value.is_a?(String)
        end
      end

      # validate the environment variables we need
      raise ArgumentError, "ENV['SRV_CODE'] cannot be blank" \
        if ENV['SRV_CODE'].blank?

      # setup the full payload
      full_payload = payload.dup
      full_payload[:short_message] = message
      full_payload[:_site_action_group] = site_action_group
      full_payload[:_site_action] = site_action
      full_payload[:_srv_code] = ENV['SRV_CODE']

      # add the request ID if available
      if RequestStore.store[:request_id]
        full_payload[:request_id] = RequestStore.store[:request_id]
      end
    end
  end
end