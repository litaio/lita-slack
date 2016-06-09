require "spec_helper"

describe Lita::Adapters::Slack::ChatService, lita: true do
  subject { described_class.new(adapter.config) }

  let(:adapter) { Lita::Adapters::Slack.new(robot) }
  let(:robot) { Lita::Robot.new(registry) }
  let(:channel) { "C2147483705" }
  let(:room) { Lita::Room.new(channel) }
  let(:username) { "TESTUSER"}
  let(:user) { Lita::User.new(username)}
  let(:room_source) { Lita::Source.new(room: channel) }

  before do
    registry.register_adapter(:slack, Lita::Adapters::Slack)
  end

  describe "#send_messages" do
    let(:attachment) { Lita::Adapters::Slack::Attachment.new("attachment text") }

    it "can send a simple message to a room source" do
      expect(subject.api).to receive(:post_message).with(channel: channel, text: "hi there")
      subject.send_messages(room_source, "hi there")
    end

    it "can send a simple message to a room" do
      expect(subject.api).to receive(:post_message).with(channel: channel, text: "hi there")
      subject.send_messages(room, "hi there")
    end

    it "can send a simple message to a user" do
      expect(subject.api).to receive(:post_message).with(channel: username, text: "hi there")
      subject.send_messages(user, "hi there")
    end

    it "can send a simple message to a channel" do
      expect(subject.api).to receive(:post_message).with(channel: channel, text: "hi there")
      subject.send_messages(channel, "hi there")
    end

    it "returns the JSON from post_message" do
      expect(subject.api).to receive(:post_message).with(channel: channel, text: "hi there").and_return("ok" => true)
      expect(subject.send_messages(room_source, "hi there")).to eq("ok" => true)
    end

    it "can send multiple messages" do
      expect(subject.api).to receive(:post_message).with(channel: channel, text: "a\nb")

      subject.send_messages(room_source, [ "a", "b" ])
    end

    it "can send attachments without text" do
      expect(subject.api).to receive(:post_message).with(channel: channel, attachments: [ attachment ])

      subject.send_messages(room_source, attachments: [ attachment ])
    end

    it "can send attachments, text and message arguments" do
      expect(subject.api).to receive(:post_message).with(channel: channel, text: "a\nb", attachments: [ attachment ], parse: "none")

      subject.send_messages(room_source, [ "a", "b" ], attachments: [ attachment ], parse: "none")
    end

    it "is aliased as send_message" do
      expect(subject.api).to receive(:post_message).with(channel: channel, text: "hi there")

      subject.send_message(room_source, "hi there")
    end
  end

  describe "#update_message" do
    let(:attachment) { Lita::Adapters::Slack::Attachment.new("attachment text") }
    let(:ts) { "1234.5678" }

    it "can send a simple message to a room source" do
      expect(subject.api).to receive(:chat_update).with(channel: channel, ts: ts, text: "hi there")
      subject.update_message(room_source, ts, "hi there")
    end

    it "can send a simple message to a room" do
      expect(subject.api).to receive(:chat_update).with(channel: channel, ts: ts, text: "hi there")
      subject.update_message(room, ts, "hi there")
    end

    it "can send a simple message to a user" do
      expect(subject.api).to receive(:chat_update).with(channel: username, ts: ts, text: "hi there")
      subject.update_message(user, ts, "hi there")
    end

    it "can send a simple message to a channel" do
      expect(subject.api).to receive(:chat_update).with(channel: channel, ts: ts, text: "hi there")
      subject.update_message(channel, ts, "hi there")
    end

    it "returns the JSON from update_message" do
      expect(subject.api).to receive(:chat_update).with(channel: channel, ts: ts, text: "hi there").and_return("ok" => true)
      expect(subject.update_message(room_source, ts, "hi there")).to eq("ok" => true)
    end

    it "can update with multiple messages" do
      expect(subject.api).to receive(:chat_update).with(channel: channel, ts: ts, text: "a\nb")

      subject.update_message(room_source, ts, [ "a", "b" ])
    end

    it "can send attachments without text" do
      expect(subject.api).to receive(:chat_update).with(channel: channel, ts: ts, attachments: [ attachment ])

      subject.update_message(room_source, ts, attachments: [ attachment ])
    end

    it "can send attachments, text and message arguments" do
      expect(subject.api).to receive(:chat_update).with(channel: channel, ts: ts, text: "a\nb", attachments: [ attachment ], parse: "none")

      subject.update_message(room_source, ts, [ "a", "b" ], attachments: [ attachment ], parse: "none")
    end
  end

  describe "#delete_message" do
    let(:ts) { "1234.5678" }

    it "can send a delete to a room source" do
      expect(subject.api).to receive(:chat_delete).with(channel: channel, ts: ts)
      subject.delete_message(room_source, ts)
    end

    it "can send a delete to a room" do
      expect(subject.api).to receive(:chat_delete).with(channel: channel, ts: ts)
      subject.delete_message(room, ts)
    end

    it "can send a delete to a user" do
      expect(subject.api).to receive(:chat_delete).with(channel: username, ts: ts)
      subject.delete_message(user, ts)
    end

    it "can send a delete to a channel" do
      expect(subject.api).to receive(:chat_delete).with(channel: channel, ts: ts)
      subject.delete_message(channel, ts)
    end

    it "returns the JSON from delete_message" do
      expect(subject.api).to receive(:chat_delete).with(channel: channel, ts: ts).and_return("ok" => true)
      expect(subject.delete_message(room_source, ts)).to eq("ok" => true)
    end
  end

  describe "#send_attachments" do
    let(:attachment) { Lita::Adapters::Slack::Attachment.new("attachment text") }

    it "can send a simple text attachment" do
      expect(subject.api).to receive(:post_message).with(channel: channel, attachments: [attachment])

      subject.send_attachments(room, attachment)
    end

    it "can send attachments and message arguments" do
      expect(subject.api).to receive(:post_message).with(channel: channel, attachments: [attachment], parse: "none")

      subject.send_attachments(room, attachment, parse: "none")
    end

    it "is aliased as send_attachment" do
      expect(subject.api).to receive(:post_message).with(channel: channel, attachments: [attachment])

      subject.send_attachment(room, attachment)
    end
  end
end
