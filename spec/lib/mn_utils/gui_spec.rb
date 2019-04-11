RSpec.describe MnUtilsGlobal::Gui do

  ENV['SRV_GUI_URL'] = 'http://gui_service:3020'
  it 'Returns error is invalid component' do
    expect(described_class.render_component_html(nil)).to match("")
    expect(described_class.render_component_html(1)).to match("")
    expect(described_class.render_component_html('')).to match("")
  end
end
