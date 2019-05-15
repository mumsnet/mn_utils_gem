RSpec.describe MnUtilsAuth::Sso do

  it "return nil if cookies are nil" do
    expect(described_class.instance.get_sso_user_id(nil)).to be_nil
  end

end
