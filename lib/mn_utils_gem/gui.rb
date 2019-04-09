require 'httparty'

module MnUtilsGlobal
  class Gui

    def self.render_component(component)
      Rails.cache.fetch("gui-component-#{component}", expires_in: 1.hour) do
        response = HTTP.timeout(1).get("#{ENV['SRV_GUI_URL']}/service/gui/api/v1/component/#{component}")
        json = JSON.parse(response)
        json['html'].html_safe
      end
    rescue StandardError => e
      Rails.logger.error "ViewHelper::render_gui_component error #{e.backtrace}"
      "<p>#{component.split('?')[0]}</p>".html_safe
    end
  end
end
