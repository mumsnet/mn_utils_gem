RSpec.describe MnUtilsEmail::TransactionalEmail do

  it "succeeds with valid params" do
    expect {
      MnUtilsEmail::TransactionalEmail.instance.enqueue(
          message_type: 'REGISTRATION_WELCOME',
          to_address: 'joe@example.com',
          subject: 'hello',
          fallback_text: 'hi there')
    }.not_to raise_error
  end

  it "rejects blank message type" do
    expect {
      MnUtilsEmail::TransactionalEmail.instance.enqueue(
          message_type: ' ',
          to_address: 'joe@example.com',
          subject: 'hello',
          fallback_text: 'hi there')
    }.to raise_error(ArgumentError)
  end

  it "rejects blank to address" do
    expect {
      MnUtilsEmail::TransactionalEmail.instance.enqueue(
          message_type: 'REGISTRATION_WELCOME',
          to_address: ' ',
          subject: 'hello',
          fallback_text: 'hi there')
    }.to raise_error(ArgumentError)
  end

  it "rejects blank subject" do
    expect {
      MnUtilsEmail::TransactionalEmail.instance.enqueue(
          message_type: 'REGISTRATION_WELCOME',
          to_address: 'joe@example.com',
          subject: ' ',
          fallback_text: 'hi there')
    }.to raise_error(ArgumentError)
  end

  it "rejects blank fallback text" do
    expect {
      MnUtilsEmail::TransactionalEmail.instance.enqueue(
          message_type: 'REGISTRATION_WELCOME',
          to_address: 'joe@example.com',
          subject: 'hello',
          fallback_text: ' ')
    }.to raise_error(ArgumentError)
  end

  it "rejects invalid to address" do
    expect {
      MnUtilsEmail::TransactionalEmail.instance.enqueue(
          message_type: 'REGISTRATION_WELCOME',
          to_address: 'joeexample.com',
          subject: 'hello',
          fallback_text: 'hi there')
    }.to raise_error(ArgumentError)
  end

end
