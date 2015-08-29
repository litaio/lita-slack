require "spec_helper"

describe Lita::Adapters::Slack::ChatService, lita: true do
  subject { described_class.new(adapter.config) }

  let(:adapter) { Lita::Adapters::Slack.new(robot) }
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
end
