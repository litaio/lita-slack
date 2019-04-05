require "spec_helper"

describe Lita::Adapters::Slack::ChatService, lita: true do
  subject { described_class.new(adapter.config) }

  let(:adapter) { Lita::Adapters::Slack.new(robot) }
  let(:robot) { Lita::Robot.new(registry) }
  let(:room) { Lita::Room.new("C2147483705") }
  let(:user) { Lita::User.new('U023BECGF') }

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

  describe "#send_ephemeral_attachments" do
    let(:attachment) { Lita::Adapters::Slack::Attachment.new("attachment text") }

    it "can send an ephemeral text attachment" do
      expect(subject.api).to receive(:send_ephemeral_attachments).with(room, user, [attachment])

      subject.send_ephemeral_attachments(room, user, [attachment])
    end

    it "is aliased as send_ephemeral_attachment" do
      expect(subject.api).to receive(:send_ephemeral_attachments).with(room, user, [attachment])

      subject.send_ephemeral_attachment(room, user, [attachment])
    end
  end

  describe "#send_ephemeral_messages" do
    let(:attachment) { Lita::Adapters::Slack::Attachment.new("attachment text") }

    it "can send an ephemeral message" do
      expect(subject.api).to receive(:send_ephemeral_messages).with(room, user, ['foo'])

      subject.send_ephemeral_messages(room, user, ['foo'])
    end

    it "is aliased as send_ephemeral_message" do
      expect(subject.api).to receive(:send_ephemeral_messages).with(room, user, ['foo'])

      subject.send_ephemeral_message(room, user, ['foo'])
    end
  end
end
