require "spec_helper"

describe Lita::Adapters::Slack::RTMConnection, lita: true do
  subject { described_class.new(token, rtm_start_response) }

  let(:api) { instance_double("Lita::Adapters::Slack::API") }
  let(:rtm_start_response) do
    Lita::Adapters::Slack::RTMStartResponse.new(nil, [], [], "wss://example.com/")
  end
  let(:token) { 'abcd-1234567890-hWYd21AmMH2UHAkx29vb5c1Y' }
  let(:queue) { Queue.new }

  describe ".build" do
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

  describe "#run" do
    it "starts the reactor" do
      thread = Thread.new { subject.run(queue) }
      thread.abort_on_exception = true
      queue.pop

      expect(EM.reactor_running?).to be_truthy

      subject.shut_down
    end

    it "creates the WebSocket" do
      thread = Thread.new { subject.run(queue) }
      thread.abort_on_exception = true

      expect(queue.pop).to be_an_instance_of(Faye::WebSocket::Client)

      subject.shut_down
    end
  end
end
