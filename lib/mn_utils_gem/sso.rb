require 'singleton'
require 'json'

module MnUtilsAuth
  class Sso

    include Singleton

    SSO_COOKIE_NAME         = :mnsso.freeze
    SSO_COOKIE_VALUE_PREFIX = "#{SSO_COOKIE_NAME}_".freeze

    def initialize
      @logger = defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
    end

    def get_sso_user_id(cookies)
      raise ArgumentError, "ENV['MN_REDIS_URL'] is required" \
          unless ENV.key? 'MN_REDIS_URL'
      raise ArgumentError, "ENV['COOKIE_DOMAIN'] is required" \
          unless ENV.key? 'COOKIE_DOMAIN'
      parsed = get_sso cookies
      return nil if parsed.nil?
      parsed[:user_id]
    rescue Exception => e
      @logger.error e
      nil
    end

    def get_sso(cookies)
      raise ArgumentError, "ENV['MN_REDIS_URL'] is required" \
          unless ENV.key? 'MN_REDIS_URL'
      raise ArgumentError, "ENV['COOKIE_DOMAIN'] is required" \
          unless ENV.key? 'COOKIE_DOMAIN'
      return RequestStore.store[:sso] if RequestStore.store[:sso]
      return nil if cookies.nil? || cookies[SSO_COOKIE_NAME].nil? || redis_server.nil?
      json = redis_server.get(cookies[SSO_COOKIE_NAME])
      return nil if json.nil?
      parsed = JSON.parse(json, symbolize_names: true)
      return nil unless parsed.is_a?(Hash)
      RequestStore.store[:sso] = parsed
      parsed
    rescue Exception => e
      @logger.error e
      nil
    end

    def set_sso(cookies, user_id, persistent, other_attributes = {})
      raise ArgumentError, "ENV['MN_REDIS_URL'] is required" \
          unless ENV.key? 'MN_REDIS_URL'
      raise ArgumentError, "ENV['COOKIE_DOMAIN'] is required" \
          unless ENV.key? 'COOKIE_DOMAIN'
      return if cookies.nil? || user_id.blank? || RequestStore.store[:sso] || redis_server.nil?
      value = other_attributes.reverse_merge({ user_id: user_id })
      redis_ttl = (persistent) ? 1.year.to_i : 1.day.to_i
      if cookies[SSO_COOKIE_NAME].nil?
        cookie = set_sso_cookie cookies, persistent
        redis_server.set(cookie, JSON[value], ex: redis_ttl)
        RequestStore.store[:sso] = value
      else
        if !redis_server.get(cookies[SSO_COOKIE_NAME])
          cookie = set_sso_cookie cookies, persistent
          redis_server.set(cookie, JSON[value], ex: redis_ttl)
          RequestStore.store[:sso] = value
        end
      end
    end

    def delete_sso(cookies)
      raise ArgumentError, "ENV['MN_REDIS_URL'] is required" \
          unless ENV.key? 'MN_REDIS_URL'
      raise ArgumentError, "ENV['COOKIE_DOMAIN'] is required" \
          unless ENV.key? 'COOKIE_DOMAIN'
      if cookies[SSO_COOKIE_NAME]
        redis_server.del(cookies[SSO_COOKIE_NAME])
        cookies.delete SSO_COOKIE_NAME
      end
      if RequestStore.store[:sso]
        RequestStore.store[:sso] = nil
      end
    end

    private

    def set_sso_cookie(cookies, persistent)
      expiry = persistent ? 1.year.from_now : 1.day.from_now
      cookies[SSO_COOKIE_NAME] = {
          value: cookie_value,
          domain: ENV['COOKIE_DOMAIN'],
          expires: expiry,
          secure: true,
          httponly: true
      }
      cookies[SSO_COOKIE_NAME]
    end

    def redis_server
      @redis_server ||= Redis.new(
          url: ENV['MN_REDIS_URL'],
          ssl: SharedService.string_to_bool(ENV['MN_REDIS_SSL']),
          semian: {
              name: 'user-service',
              tickets: 4,
              success_threshold: 1,
              error_threshold: 4,
              error_timeout: 10,
              bulkhead: false
          }
      )
    rescue StandardError => e
      @logger.error e
      nil
    end

    def cookie_value
      "#{SSO_COOKIE_VALUE_PREFIX}#{SecureRandom.uuid}"
    end

  end
end