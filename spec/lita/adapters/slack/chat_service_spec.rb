require "spec_helper"
require "support/expect_api_call"

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

  include ExpectApiCall

  describe "#post_message" do
    it "can send a simple message to a room source" do
      expect_api_call("chat.postMessage", channel: channel, text: "hi there")
      subject.post_message(room_source, text: "hi there")
    end

    it "can send a simple message to a room" do
      expect_api_call("chat.postMessage", channel: channel, text: "hi there")
      subject.post_message(room, text: "hi there")
    end

    it "can send a simple message to a user" do
      expect_api_call("chat.postMessage", channel: username, text: "hi there")
      subject.post_message(user, text: "hi there")
    end

    it "can send a simple message to a channel" do
      expect_api_call("chat.postMessage", channel: channel, text: "hi there")
      subject.post_message(channel, text: "hi there")
    end

    it "returns the JSON from post_message" do
      expect_api_call("chat.postMessage", channel: channel, text: "hi there")
      expect(subject.post_message(room_source, text: "hi there")).to eq("ok" => true)
    end

    it "can send attachments without text" do
      expect_api_call("chat.postMessage", channel: channel, attachments: %|[{"fallback":"attachment text","text":"attachment text"}]|)
      attachment = Lita::Adapters::Slack::Attachment.new("attachment text")
      subject.post_message(room_source, attachments: [ attachment ])
    end

    it "can send attachments, text and message arguments" do
      expect_api_call("chat.postMessage", channel: channel, text: "a\nb", attachments: %|[{"fallback":"attachment text","text":"attachment text"}]|, parse: "none")
      attachment = Lita::Adapters::Slack::Attachment.new("attachment text")
      subject.post_message(room_source, text: "a\nb", attachments: [ attachment ], parse: "none")
    end

    it "can send all arguments" do
      expect_api_call("chat.postMessage",
        channel: channel,
        text: "a",
        attachments: %|[{"fallback":"attachment text","text":"attachment text"}]|,
        parse: "none",
        link_names: "1",
        unfurl_links: true,
        unfurl_media: true,
        mrkdwn: "0",
        as_user: false,
        username: "bot",
        icon_emoji: ":lol:",
        icon_url: "http://kittens.com/cute.jpeg"
      )
      attachment = Lita::Adapters::Slack::Attachment.new("attachment text")
      subject.post_message(
        channel,
        text: "a",
        attachments: [ attachment ],
        parse: "none",
        link_names: "1",
        unfurl_links: true,
        unfurl_media: true,
        mrkdwn: "0",
        as_user: false,
        username: "bot",
        icon_emoji: ":lol:",
        icon_url: "http://kittens.com/cute.jpeg"
      )
    end
  end

  describe "#update_message" do
    let(:ts) { "1234.5678" }

    it "can send a simple message to a room source" do
      expect_api_call("chat.update", channel: channel, ts: ts, text: "hi there")
      subject.update_message(room_source, ts, text: "hi there")
    end

    it "can send a simple message to a room" do
      expect_api_call("chat.update", channel: channel, ts: ts, text: "hi there")
      subject.update_message(room, ts, text: "hi there")
    end

    it "can send a simple message to a user" do
      expect_api_call("chat.update", channel: username, ts: ts, text: "hi there")
      subject.update_message(user, ts, text: "hi there")
    end

    it "can send a simple message to a channel" do
      expect_api_call("chat.update", channel: channel, ts: ts, text: "hi there")
      subject.update_message(channel, ts, text: "hi there")
    end

    it "returns the JSON from update_message" do
      expect_api_call("chat.update", channel: channel, ts: ts, text: "hi there")
      expect(subject.update_message(room_source, ts, text: "hi there")).to eq("ok" => true)
    end

    it "can send attachments without text" do
      expect_api_call("chat.update", channel: channel, ts: ts, attachments: %|[{"fallback":"attachment text","text":"attachment text"}]|)
      attachment = Lita::Adapters::Slack::Attachment.new("attachment text")
      subject.update_message(room_source, ts, attachments: [ attachment ])
    end

    it "can send attachments, text and message arguments" do
      expect_api_call("chat.update", channel: channel, ts: ts, text: "a\nb", attachments: %|[{"fallback":"attachment text","text":"attachment text"}]|, parse: "none")
      attachment = Lita::Adapters::Slack::Attachment.new("attachment text")
      subject.update_message(room_source, ts, text: "a\nb", attachments: [ attachment ], parse: "none")
    end

    it "can send all arguments" do
      expect_api_call("chat.update",
        channel: channel,
        ts: ts,
        text: "a\nb",
        attachments: %|[{"fallback":"attachment text","text":"attachment text"}]|,
        parse: "none",
        link_names: "1")
      attachment = Lita::Adapters::Slack::Attachment.new("attachment text")
      subject.update_message(room_source, ts,
        text: "a\nb",
        attachments: [ attachment ],
        parse: "none",
        link_names: "1")
    end
  end

  describe "#delete_message" do
    let(:ts) { "1234.5678" }

    it "can send a delete to a room source" do
      expect_api_call("chat.delete", channel: channel, ts: ts)
      subject.delete_message(room_source, ts)
    end

    it "can send a delete to a room" do
      expect_api_call("chat.delete", channel: channel, ts: ts)
      subject.delete_message(room, ts)
    end

    it "can send a delete to a user" do
      expect_api_call("chat.delete", channel: username, ts: ts)
      subject.delete_message(user, ts)
    end

    it "can send a delete to a channel" do
      expect_api_call("chat.delete", channel: channel, ts: ts)
      subject.delete_message(channel, ts)
    end

    it "returns the JSON from delete_message" do
      expect_api_call("chat.delete", channel: channel, ts: ts)
      expect(subject.delete_message(room_source, ts)).to eq("ok" => true)
    end
  end

  describe "#send_attachments" do
    it "can send a simple text attachment" do
      expect_api_call("chat.postMessage", channel: channel, attachments: %|[{"fallback":"attachment text","text":"attachment text"}]|)
      subject.send_attachments(room, Lita::Adapters::Slack::Attachment.new("attachment text"))
    end

    it "is aliased as send_attachment" do
      expect_api_call("chat.postMessage", channel: channel, attachments: %|[{"fallback":"attachment text","text":"attachment text"}]|)
      subject.send_attachment(room, Lita::Adapters::Slack::Attachment.new("attachment text"))
    end
  end
end
