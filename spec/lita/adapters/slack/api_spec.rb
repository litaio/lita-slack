require "spec_helper"

describe Lita::Adapters::Slack::API do
  subject { described_class.new(config, stubs) }

  let(:http_status) { 200 }
  let(:token) { 'abcd-1234567890-hWYd21AmMH2UHAkx29vb5c1Y' }
  let(:config) { Lita::Adapters::Slack.configuration_builder.build }

  before do
    config.token = token
  end

  describe "#im_open" do
    let(:channel_id) { 'D024BFF1M' }
    let(:stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post('https://slack.com/api/im.open', token: token, user: user_id) do
          [http_status, {}, http_response]
        end
      end
    end
    let(:user_id) { 'U023BECGF' }

    describe "with a successful response" do
      let(:http_response) do
        MultiJson.dump({
            ok: true,
            channel: {
                id: 'D024BFF1M'
            }
        })
      end

      it "returns a response with the IM's ID" do
        response = subject.im_open(user_id)

        expect(response.id).to eq(channel_id)
      end
    end

    describe "with a Slack error" do
      let(:http_response) do
        MultiJson.dump({
          ok: false,
          error: 'invalid_auth'
        })
      end

      it "raises a RuntimeError" do
        expect { subject.im_open(user_id) }.to raise_error(
          "Slack API call to im.open returned an error: invalid_auth."
        )
      end
    end

    describe "with an HTTP error" do
      let(:http_status) { 422 }
      let(:http_response) { '' }

      it "raises a RuntimeError" do
        expect { subject.im_open(user_id) }.to raise_error(
          "Slack API call to im.open failed with status code 422."
        )
      end
    end
  end

  describe "#send_attachments" do
    let(:attachment) do
      Lita::Adapters::Slack::Attachment.new(attachment_text)
    end
    let(:attachment_text) { "attachment text" }
    let(:attachment_hash) do
      {
        fallback: fallback_text,
        text: attachment_text,
      }
    end
    let(:fallback_text) { attachment_text }
    let(:http_response) { MultiJson.dump({ ok: true }) }
    let(:room) { Lita::Room.new("C1234567890") }
    let(:stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post(
          "https://slack.com/api/chat.postMessage",
          token: token,
          as_user: true,
          channel: room.id,
          attachments: MultiJson.dump([attachment_hash]),
        ) do
          [http_status, {}, http_response]
        end
      end
    end

    context "with a simple text attachment" do
      it "sends the attachment" do
        response = subject.send_attachments(room, [attachment])

        expect(response['ok']).to be(true)
      end
    end

    context "with a different fallback message" do
      let(:attachment) do
        Lita::Adapters::Slack::Attachment.new(attachment_text, fallback: fallback_text)
      end
      let(:fallback_text) { "fallback text" }

      it "sends the attachment" do
        response = subject.send_attachments(room, [attachment])

        expect(response['ok']).to be(true)
      end
    end

    context "with all the valid options" do
      let(:attachment) do
        Lita::Adapters::Slack::Attachment.new(attachment_text, common_hash_data)
      end
      let(:attachment_hash) do
        common_hash_data.merge(fallback: attachment_text, text: attachment_text)
      end
      let(:common_hash_data) do
        {
          author_icon: "http://example.com/author.jpg",
          author_link: "http://example.com/author",
          author_name: "author name",
          color: "#36a64f",
          fields: [{
            title: "priority",
            value: "high",
            short: true,
          }, {
            title: "super long field title",
            value: "super long field value",
            short: false,
          }],
          image_url: "http://example.com/image.jpg",
          pretext: "pretext",
          thumb_url: "http://example.com/thumb.jpg",
          title: "title",
          title_link: "http://example.com/title",
        }
      end

      it "sends the attachment" do
        response = subject.send_attachments(room, [attachment])

        expect(response['ok']).to be(true)
      end
    end

    context "with a Slack error" do
      let(:http_response) do
        MultiJson.dump({
          ok: false,
          error: 'invalid_auth'
        })
      end

      it "raises a RuntimeError" do
        expect { subject.send_attachments(room, [attachment]) }.to raise_error(
          "Slack API call to chat.postMessage returned an error: invalid_auth."
        )
      end
    end

    context "with an HTTP error" do
      let(:http_status) { 422 }
      let(:http_response) { '' }

      it "raises a RuntimeError" do
        expect { subject.send_attachments(room, [attachment]) }.to raise_error(
          "Slack API call to chat.postMessage failed with status code 422."
        )
      end
    end
  end

  describe "#send_messages" do
    let(:messages) { ["attachment text"] }
    let(:http_response) { MultiJson.dump({ ok: true }) }
    let(:room) { "C1234567890" }
    let(:stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post(
          "https://slack.com/api/chat.postMessage",
          token: token,
          as_user: true,
          channel: room,
          text: messages.join("\n"),
          parse: nil,
        ) do
          [http_status, {}, http_response]
        end
      end
    end

    context "with a simple text attachment" do
      it "sends the attachment" do
        response = subject.send_messages(room, messages)

        expect(response['ok']).to be(true)
      end
    end

    context "with a different fallback message" do
      let(:attachment) do
        Lita::Adapters::Slack::Attachment.new(attachment_text, fallback: fallback_text)
      end
      let(:fallback_text) { "fallback text" }

      it "sends the attachment" do
        response = subject.send_messages(room, messages)

        expect(response['ok']).to be(true)
      end
    end

    context "with all the valid options" do
      let(:attachment) do
        Lita::Adapters::Slack::Attachment.new(attachment_text, common_hash_data)
      end
      let(:attachment_hash) do
        common_hash_data.merge(fallback: attachment_text, text: attachment_text)
      end
      let(:common_hash_data) do
        {
          author_icon: "http://example.com/author.jpg",
          author_link: "http://example.com/author",
          author_name: "author name",
          color: "#36a64f",
          fields: [{
            title: "priority",
            value: "high",
            short: true,
          }, {
            title: "super long field title",
            value: "super long field value",
            short: false,
          }],
          image_url: "http://example.com/image.jpg",
          pretext: "pretext",
          thumb_url: "http://example.com/thumb.jpg",
          title: "title",
          title_link: "http://example.com/title",
        }
      end

      it "sends the attachment" do
        response = subject.send_messages(room, messages)

        expect(response['ok']).to be(true)
      end
    end

    context "with a Slack error" do
      let(:http_response) do
        MultiJson.dump({
          ok: false,
          error: 'invalid_auth'
        })
      end

      it "raises a RuntimeError" do
        expect { subject.send_messages(room, messages) }.to raise_error(
          "Slack API call to chat.postMessage returned an error: invalid_auth."
        )
      end
    end

    context "with an HTTP error" do
      let(:http_status) { 422 }
      let(:http_response) { '' }

      it "raises a RuntimeError" do
        expect { subject.send_messages(room, messages) }.to raise_error(
          "Slack API call to chat.postMessage failed with status code 422."
        )
      end
    end
  end

  describe "#set_topic" do
    let(:channel) { 'C1234567890' }
    let(:topic) { 'Topic' }
    let(:stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post(
          'https://slack.com/api/channels.setTopic',
          token: token,
          channel: channel,
          topic: topic
        ) do
          [http_status, {}, http_response]
        end
      end
    end

    context "with a successful response" do
      let(:http_response) do
        MultiJson.dump({
          ok: true,
          topic: 'Topic'
        })
      end

      it "returns a response with the channel's topic" do
        response = subject.set_topic(channel, topic)

        expect(response['topic']).to eq(topic)
      end
    end

    context "with a Slack error" do
      let(:http_response) do
        MultiJson.dump({
          ok: false,
          error: 'invalid_auth'
        })
      end

      it "raises a RuntimeError" do
        expect { subject.set_topic(channel, topic) }.to raise_error(
          "Slack API call to channels.setTopic returned an error: invalid_auth."
        )
      end
    end

    context "with an HTTP error" do
      let(:http_status) { 422 }
      let(:http_response) { '' }

      it "raises a RuntimeError" do
        expect { subject.set_topic(channel, topic) }.to raise_error(
          "Slack API call to channels.setTopic failed with status code 422."
        )
      end
    end
  end

  describe "#rtm_start" do
    let(:http_status) { 200 }
    let(:stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post('https://slack.com/api/rtm.start', token: token) do
          [http_status, {}, http_response]
        end
      end
    end

    describe "with a successful response" do
      let(:http_response) do
        MultiJson.dump({
          ok: true,
          url: 'wss://example.com/',
          users: [{ id: 'U023BECGF' }],
          ims: [{ id: 'D024BFF1M' }],
          self: { id: 'U12345678' },
          channels: [{ id: 'C1234567890' }],
          groups: [{ id: 'G0987654321' }],
        })
      end

      it "has data on the bot user" do
        response = subject.rtm_start

        expect(response.self.id).to eq('U12345678')
      end

      it "has an array of IMs" do
        response = subject.rtm_start

        expect(response.ims[0].id).to eq('D024BFF1M')
      end

      it "has an array of users" do
        response = subject.rtm_start

        expect(response.users[0].id).to eq('U023BECGF')
      end

      it "has a WebSocket URL" do
        response = subject.rtm_start

        expect(response.websocket_url).to eq('wss://example.com/')
      end
    end
  end
end
