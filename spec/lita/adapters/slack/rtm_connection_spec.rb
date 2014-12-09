require "spec_helper"

describe Lita::Adapters::Slack::RTMConnection do
  let(:token) { 'abcd-1234567890-hWYd21AmMH2UHAkx29vb5c1Y' }

  describe ".build" do
    let(:api) { instance_double("Lita::Adapters::Slack::API") }
    let(:rtm_start_response) do
      Lita::Adapters::Slack::RTMStartResponse.new(nil, [], [], "wss://example.com/")
    end

    before do
      allow(Lita::Adapters::Slack::API).to receive(:new).with(token).and_return(api)
      allow(api).to receive(:rtm_start).and_return(rtm_start_response)
    end

    it "constructs a new RTMConnection with the results of rtm.start data" do
      expect(described_class.build(token)).to be_an_instance_of(described_class)
    end

    it "creates users with the results of rtm.start data" do
      expect(Lita::Adapters::Slack::UserCreator).to receive(:create_users)

      described_class.build(token)
    end
  end
end
