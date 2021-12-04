require "spec_helper"

describe Lita::Adapters::Slack::RTMConnection, lita: true do
  def with_websocket(subject, queue)
    thread = Thread.new { subject.run(queue, ping: nil) }
    thread.abort_on_exception = true
    yield queue.pop
    subject.shut_down
    thread.join
  end

  subject { described_class.new(robot, config, rtm_connect_response) }

  let(:api) { instance_double("Lita::Adapters::Slack::API") }
  let(:registry) { Lita::Registry.new }
  let(:robot) { Lita::Robot.new(registry) }

  let(:rtm_connect_response) do
    Lita::Adapters::Slack::TeamData.new(
      'T2U81E2FP',
      'SlackDemo',
      'slackdemo',
      Lita::Adapters::Slack::SlackUser.new('U12345678', 'carl', nil, {}),
      "wss://example.com/"
    )
  end
  let(:token) { 'abcd-1234567890-hWYd21AmMH2UHAkx29vb5c1Y' }
  let(:queue) { Queue.new }
  let(:proxy_url) { "http://example.com:3128" }
  let(:config) { Lita::Adapters::Slack.configuration_builder.build }

  before do
    config.token = token
  end

  describe ".build" do
    before do
      allow(Lita::Adapters::Slack::API).to receive(:new).with(config).and_return(api)
      allow(api).to receive(:rtm_connect).and_return(rtm_connect_response)
    end

    it "constructs a new RTMConnection with the results of rtm.connect data" do
      expect(described_class.build(robot, config)).to be_an_instance_of(described_class)
    end
  end

  describe "#run" do
    let(:event) { double('Event', data: '{}') }
    let(:message_handler) { instance_double('Lita::Adapters::Slack::MessageHandler') }

    it "creates the WebSocket" do
      with_websocket(subject, queue) do |websocket|
        expect(websocket).to be_an_instance_of(Faye::WebSocket::Client)
      end
    end

    context "with a proxy server specified" do
      before do
        config.proxy = proxy_url
      end

      it "creates the WebSocket" do
        with_websocket(subject, queue) do |websocket|
          expect(websocket).to be_an_instance_of(Faye::WebSocket::Client)
        end
      end
    end

    it "dispatches incoming data to MessageHandler" do
      allow(Lita::Adapters::Slack::EventLoop).to receive(:defer).and_yield
      allow(Lita::Adapters::Slack::MessageHandler).to receive(:new).with(
        robot,
        'U12345678',
        {},
      ).and_return(message_handler)

      expect(message_handler).to receive(:handle)

      # Testing private methods directly is bad, but it's difficult to get
      # the timing right when testing it by emitting the "message" event on
      # the WebSocket.
      subject.send(:receive_message, event)
    end

    context "when the WebSocket is closed from outside" do
      it "shuts down the reactor" do
        with_websocket(subject, queue) do |websocket|
            sleep 0.1 # Since this code is run in a thread, we need to wait for it to finish
            websocket.close
            expect(EM.stopping?).to be_truthy
          end
      end
    end

  end

  describe "#send_messages" do
    let(:message_json) { MultiJson.dump(id: 1, type: 'message', text: 'hi', channel: channel_id) }
    let(:channel_id) { 'C024BE91L' }
    let(:websocket) { instance_double("Faye::WebSocket::Client") }

    before do
      # TODO: Don't stub what you don't own!
      allow(Faye::WebSocket::Client).to receive(:new).and_return(websocket)
      allow(websocket).to receive(:on)
      allow(websocket).to receive(:close)
      allow(Lita::Adapters::Slack::EventLoop).to receive(:defer).and_yield
    end

    it "writes messages to the WebSocket" do
      with_websocket(subject, queue) do |websocket|
        expect(websocket).to receive(:send).with(message_json)

        subject.send_messages(channel_id, ['hi'])
      end
    end

    it "raises an ArgumentError if the payload is too large" do
      with_websocket(subject, queue) do |websocket|
        expect do
          subject.send_messages(channel_id, ['x' * 16_001])
        end.to raise_error(ArgumentError)
      end
    end
  end
end
