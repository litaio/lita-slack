require "spec_helper"

describe Lita::Adapters::Slack::ChatService, lita: true do
  subject { described_class.new(adapter.config) }

  let(:adapter) { Lita::Adapters::Slack.new(robot) }
  let(:robot) { Lita::Robot.new(registry) }
  let(:room) { Lita::Room.new("C2147483705") }
  let(:room_source) { Lita::Source.new(room: "C2147483705") }

  before do
    registry.register_adapter(:slack, Lita::Adapters::Slack)
  end

  describe "#send_messages" do
    let(:attachment) { Lita::Adapters::Slack::Attachment.new("attachment text") }

    it "can send a simple message" do
      expect(subject.api).to receive(:post_message).with(channel: room.id, text: "hi there")

      subject.send_messages(room_source, "hi there")
    end

    it "can send multiple messages" do
      expect(subject.api).to receive(:post_message).with(channel: room.id, text: "a\nb")

      subject.send_messages(room_source, [ "a", "b" ])
    end

    it "can send attachments without text" do
      expect(subject.api).to receive(:post_message).with(channel: room.id, attachments: [ attachment ])

      subject.send_messages(room_source, attachments: [ attachment ])
    end

    it "can send attachments, text and message arguments" do
      expect(subject.api).to receive(:post_message).with(channel: room.id, text: "a\nb", attachments: [ attachment ], parse: "none")

      subject.send_messages(room_source, [ "a", "b" ], attachments: [ attachment ], parse: "none")
    end

    it "is aliased as send_message" do
      expect(subject.api).to receive(:post_message).with(channel: room.id, text: "hi there")

      subject.send_message(room_source, "hi there")
    end
  end

  describe "#send_attachments" do
    let(:attachment) { Lita::Adapters::Slack::Attachment.new("attachment text") }

    it "can send a simple text attachment" do
      expect(subject.api).to receive(:post_message).with(channel: room.id, attachments: [attachment])

      subject.send_attachments(room, attachment)
    end

    it "can send attachments and message arguments" do
      expect(subject.api).to receive(:post_message).with(channel: room.id, attachments: [attachment], parse: "none")

      subject.send_attachments(room, attachment, parse: "none")
    end

    it "is aliased as send_attachment" do
      expect(subject.api).to receive(:post_message).with(channel: room.id, attachments: [attachment])

      subject.send_attachment(room, attachment)
    end
  end
end
