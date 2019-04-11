RSpec.describe MnUtilsLogging::SiteAction do

  it "succeeds without payload" do
    expect { MnUtilsLogging::SiteAction.instance.log("hello", :test_event_1) }.not_to raise_error
  end

  it "succeeds with a valid payload" do
    expect { MnUtilsLogging::SiteAction.instance.log("hello", :test_event_1, { _a_field: 'a value' }) }.not_to raise_error
  end

  it "rejects blank message" do
    expect { MnUtilsLogging::SiteAction.instance.log("", :test_event_1)}.to raise_error(ArgumentError)
  end

  it "rejects non symbol site_action" do
    expect { MnUtilsLogging::SiteAction.instance.log("hello", 'test_event_1')}.to raise_error(ArgumentError)
  end

  it "rejects non hash payload" do
    expect { MnUtilsLogging::SiteAction.instance.log("hello", :test_event_1, 'payload')}.to raise_error(ArgumentError)
  end

  it "rejects site_action that is not in the list" do
    expect { MnUtilsLogging::SiteAction.instance.log("hello", :test_event_3)}.to raise_error(ArgumentError)
  end

  it "rejects payload with non symbol key" do
    expect { MnUtilsLogging::SiteAction.instance.log("hello", :test_event_1, { '_a_field' => 'a value' })}.to raise_error(ArgumentError)
  end

  it "rejects payload with key that does not begin with underscore" do
    expect { MnUtilsLogging::SiteAction.instance.log("hello", :test_event_1, { a_field: 'a value' })}.to raise_error(ArgumentError)
  end

  it "rejects payload with key that too short" do
    expect { MnUtilsLogging::SiteAction.instance.log("hello", :test_event_1, { a: 'a value' })}.to raise_error(ArgumentError)
  end

  it "rejects payload with key that is _id" do
    expect { MnUtilsLogging::SiteAction.instance.log("hello", :test_event_1, { _id: 'a value' })}.to raise_error(ArgumentError)
  end

  it "rejects payload with value that is not a string or symbol" do
    expect { MnUtilsLogging::SiteAction.instance.log("hello", :test_event_1, { _a_field: ['a value'] })}.to raise_error(ArgumentError)
  end

end
