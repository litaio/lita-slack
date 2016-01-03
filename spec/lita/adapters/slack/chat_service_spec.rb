require "spec_helper"

describe Lita::Adapters::Slack::ChatService, lita: true do
  subject { described_class.new(adapter.config) }

  let(:adapter) { Lita::Adapters::Slack.new(robot) }
  let(:registry) { Lita::Registry.new }
  let(:robot) { Lita::Robot.new(registry) }
  let(:room) { Lita::Room.new("C2147483705") }

  before do
    registry.register_adapter(:slack, Lita::Adapters::Slack)
  end

  describe "#send_attachments" do
    let(:attachment) { Lita::Adapters::Slack::Attachment.new("attachment text") }

    it "can send a simple text attachment" do
      expect(subject.api).to receive(:send_attachments).with(room, [attachment])

      subject.send_attachments(room, attachment)
    end

    it "is aliased as send_attachment" do
      expect(subject.api).to receive(:send_attachments).with(room, [attachment])

      subject.send_attachment(room, attachment)
    end
  end

  describe "#add_reaction" do
    let(:message) { Lita::Message.new(robot, "Hello", Lita::Source.new(room: room)) }
    let(:name) { "thumbsup" }

    it "can respond with a reaction" do
      expect(subject.api).to receive(:add_reaction).with(message, name)

      subject.add_reaction(message, name)
    end
  end
end
