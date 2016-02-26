require "spec_helper"

describe Lita::Adapters::Slack, lita: true do
  subject { described_class.new(robot) }

  let(:robot) { Lita::Robot.new(registry) }
  let(:rtm_connection) { instance_double('Lita::Adapters::Slack::RTMConnection') }
  let(:token) { 'abcd-1234567890-hWYd21AmMH2UHAkx29vb5c1Y' }

  before do
    registry.register_adapter(:slack, described_class)
    registry.config.adapters.slack.token = token

    allow(
      described_class::RTMConnection
    ).to receive(:build).with(robot, subject.config).and_return(rtm_connection)
    allow(rtm_connection).to receive(:run)
  end

  it "registers with Lita" do
    expect(Lita.adapters[:slack]).to eql(described_class)
  end

  describe "#chat_service" do
    it "returns an object with Slack-specific methods" do
      expect(subject.chat_service).to be_an_instance_of(described_class::ChatService)
    end
  end

  describe "#mention_format" do
    it "returns the name prefixed with an @" do
      expect(subject.mention_format("carl")).to eq("@carl")
    end
  end

  describe "#run" do
    it "starts the RTM connection" do
      expect(rtm_connection).to receive(:run)

      subject.run
    end

    it "does nothing if the RTM connection is already created" do
      expect(rtm_connection).to receive(:run).once

      subject.run
      subject.run
    end
  end

  describe "#roster" do
    describe "via the Web API, retrieving the roster for a channel" do
      let(:room_source) { Lita::Source.new(room: 'C024BE91L') }
      let(:response) do
        {
          ok: true,
          channel: {
              members: ['C024BE91L']
          }
        }
      end
      let(:api) { instance_double('Lita::Adapters::Slack::API') }

      before do
        allow(Lita::Adapters::Slack::API).to receive(:new).with(subject.config).and_return(api)
      end

      it "returns UID(s)" do
        expect(subject).to receive(:channel_roster).with(room_source.room_object.id, api)

        subject.roster(room_source.room_object)
      end
    end

    describe "via the Web API, retrieving the roster for a group/mpim channel" do
      let(:room_source) { Lita::Source.new(room: 'G024BE91L') }
      let(:response) do
        {
          ok: true,
          groups: [{ id: 'G024BE91L' }]
        }
      end
      let(:api) { instance_double('Lita::Adapters::Slack::API') }

      before do
        allow(Lita::Adapters::Slack::API).to receive(:new).with(subject.config).and_return(api)
      end

      it "returns UID(s)" do
        expect(subject).to receive(:group_roster).with(room_source.room_object.id, api).and_return(%q{})
        expect(subject).to receive(:mpim_roster).with(room_source.room_object.id, api).and_return(%q{G024BE91L})

        subject.roster(room_source.room_object)
      end
    end

    describe "via the Web API, retrieving the roster for an im channel" do
      let(:room_source) { Lita::Source.new(room: 'D024BFF1M') }
      let(:response) do
        {
          ok: true,
          ims: [{ id: 'D024BFF1M' }]
        }
      end
      let(:api) { instance_double('Lita::Adapters::Slack::API') }

      before do
        allow(Lita::Adapters::Slack::API).to receive(:new).with(subject.config).and_return(api)
      end

      it "returns UID" do
        expect(subject).to receive(:im_roster).with(room_source.room_object.id, api)

        subject.roster(room_source.room_object)
      end
    end
  end

  describe "#send_messages" do
    let(:room_source) { Lita::Source.new(room: 'C024BE91L') }
    let(:user) { Lita::User.new('U023BECGF') }
    let(:user_source) { Lita::Source.new(user: user) }
    let(:private_message_source) do
      Lita::Source.new(room: 'C024BE91L', user: user, private_message: true)
    end

    describe "via the Web API" do
      let(:api) { instance_double('Lita::Adapters::Slack::API') }

      before do
        allow(Lita::Adapters::Slack::API).to receive(:new).with(subject.config).and_return(api)
      end

      it "does not send via the RTM api" do
        expect(rtm_connection).to_not receive(:send_messages)
        expect(api).to receive(:send_messages).with(room_source.room, ['foo'])

        subject.send_messages(room_source, ['foo'])
      end
    end
  end

  describe "#set_topic" do
    let(:api) { instance_double('Lita::Adapters::Slack::API') }

    before do
      allow(Lita::Adapters::Slack::API).to receive(:new).with(subject.config).and_return(api)
      allow(api).to receive(:set_topic).and_return(Hash.new)
    end

    it "sets a new topic for the room" do
      source = instance_double("Lita::Source", room: 'C1234567890')
      expect(api).to receive(:set_topic).with('C1234567890', 'Topic')
      subject.set_topic(source, 'Topic')
    end
  end

  describe "#shut_down" do
    before { allow(rtm_connection).to receive(:shut_down) }

    it "shuts down the RTM connection" do
      expect(rtm_connection).to receive(:shut_down)

      subject.run
      subject.shut_down
    end

    it "triggers a :disconnected event" do
      expect(robot).to receive(:trigger).with(:disconnected)

      subject.run
      subject.shut_down
    end

    it "does nothing if the RTM connection hasn't been created yet" do
      expect(rtm_connection).not_to receive(:shut_down)

      subject.shut_down
    end
  end
end
