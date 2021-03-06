require 'httparty'

module MnUtilsGlobal
  class Gui

    def self.render_component(component, options = {})
      Rails.cache.fetch(['MnUtilsGlobal', 'Gui', 'render_component', component, options.to_s], expires_in: 1.hour) do
        render_component_html(component, options)
      end
    end

    private

    def self.render_component_html(component, options = {})
      validate_component(component)
      response = HTTParty.get("#{ENV['SRV_GUI_URL']}/api/v1/component/#{component}", { timeout: 1, query: options })
      json = JSON.parse(response.body)
      validate_json(json)
      json['html'].html_safe
    rescue StandardError => e
      logger = defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
      logger.error e.message
      logger.error e.backtrace.join("\n")
      return ''
    end

    def self.validate_component(component)
      raise ArgumentError, 'Component must not be nil' \
        if component.nil?
      raise ArgumentError, 'Component connot be blank' \
        if component.blank?
      raise ArgumentError, 'Component must be a string' \
        unless component.is_a?(String)
      raise ArgumentError, "ENV['SRV_GUI_URL'] is required" \
        unless ENV.key? 'SRV_GUI_URL'
    end

    def self.validate_json(json)
      raise ArgumentError, 'json is empty or nil' \
        if (json.nil? || json.blank?) && (json['html'].nil? || json['html'].blank?)
    end

  end
end
