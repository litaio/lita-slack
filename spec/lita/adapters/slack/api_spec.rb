require "spec_helper"

describe Lita::Adapters::Slack::API do
  subject { described_class.new(config, stubs) }
  let(:api) { subject }
  # Stubs are empty by default. Override or call expect_post to add stubs.
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }

  let(:http_status) { 200 }
  let(:token) { 'abcd-1234567890-hWYd21AmMH2UHAkx29vb5c1Y' }
  let(:config) { Lita::Adapters::Slack.configuration_builder.build }

  before do
    config.token = token
  end

  #
  # Add an expected Slack API POST request/response.
  #
  # @param method [String] Slack API method (e.g. chat.postMessage)
  # @param raw_response [Integer, Hash, String] Raw response (overrides
  #   everything else, use to return errors and invalid bodies).
  # @param response [Hash] The response to send. Will be JSON-encoded before
  #   sending. Defaults to `{ ok: true }`.
  # @param token [String] The token to send. Defaults to the test instance's
  #   `let(:token)` variable.
  # @param arguments [Hash] The arguments to send. Array or Hash values will be
  #   JSON-encoded.
  #
  def expect_post(method, raw_response: nil, response: { ok: true }, token: self.token, **arguments)
    # Hash and Array arguments are JSON-encoded
    arguments = arguments.dup
    arguments.each do |key, value|
      case arguments[key]
      when Array, Hash
        arguments[key] = MultiJson.dump(value)
      end
    end
    unique_object = Object.new

    # Expect the post
    stubs.post("http://slack.com/api/#{method}", token: token, **arguments) do
      raw_response || [200, {}, MultiJson.dump(response)]
    end
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
          "Slack API call to im.open failed with status code 422: ''. Headers: {}"
        )
      end
    end
  end

  describe "#channels_info" do
    let(:channel_id) { 'C024BE91L' }
    let(:stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post('https://slack.com/api/channels.info', token: token, channel: channel_id) do
          [http_status, {}, http_response]
        end
      end
    end

    describe "with a successful response" do
      let(:http_response) do
        MultiJson.dump({
            ok: true,
            channel: {
                id: 'C024BE91L'
            }
        })
      end

      it "returns a response with the Channel's ID" do
        response = subject.channels_info(channel_id)

        expect(response['channel']['id']).to eq(channel_id)
      end
    end

    describe "with a Slack error" do
      let(:http_response) do
        MultiJson.dump({
          ok: false,
          error: 'channel_not_found'
        })
      end

      it "raises a RuntimeError" do
        expect { subject.channels_info(channel_id) }.to raise_error(
          "Slack API call to channels.info returned an error: channel_not_found."
        )
      end
    end

    describe "with an HTTP error" do
      let(:http_status) { 422 }
      let(:http_response) { '' }

      it "raises a RuntimeError" do
        expect { subject.channels_info(channel_id) }.to raise_error(
          "Slack API call to channels.info failed with status code 422: ''. Headers: {}"
        )
      end
    end
  end

  describe "#channels_list" do
    let(:channel_id) { 'C024BE91L' }
    let(:stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post('https://slack.com/api/channels.list', token: token) do
          [http_status, {}, http_response]
        end
      end
    end

    describe "with a successful response" do
      let(:http_response) do
        MultiJson.dump({
            ok: true,
            channel: [{
                id: 'C024BE91L'
            }]
        })
      end

      it "returns a response with the Channel's ID" do
        response = subject.channels_list

        expect(response['channel'].first['id']).to eq(channel_id)
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
        expect { subject.channels_list }.to raise_error(
          "Slack API call to channels.list returned an error: invalid_auth."
        )
      end
    end

    describe "with an HTTP error" do
      let(:http_status) { 422 }
      let(:http_response) { '' }

      it "raises a RuntimeError" do
        expect { subject.channels_list }.to raise_error(
          "Slack API call to channels.list failed with status code 422: ''. Headers: {}"
        )
      end
    end
  end

  describe "#chat_update" do
    # Default values; we don't care what they are, just that they are there
    let(:channel) { "test" }
    let(:ts) { "1234.5678" }
    let(:text) { "hi there" }

    it "sends simple text updates" do
      expect_post("chat.update", channel: channel, ts: ts, text: text, as_user: true)
      expect(
        api.chat_update(channel: channel, ts: ts, text: text)
      ).to eq("ok" => true)
    end

    it "overrides default as_user when passed" do
      expect_post("chat.update", channel: channel, ts: ts, text: text, as_user: false)
      expect(
        api.chat_update(channel: channel, ts: ts, text: text, as_user: false)
      ).to eq("ok" => true)
    end

    it "sends attachments and options" do
      expect_post("chat.update", channel: channel, ts: ts, attachments: [{text: text}], parse: "none", as_user: true)
      expect(
        api.chat_update(channel: channel, ts: ts, attachments: [{text: text}], parse: "none")
      ).to eq("ok" => true)
    end

    it "returns whatever it gets back" do
      expect_post("chat.update", channel: channel, ts: ts, attachments: [{text: text}], as_user: true,
        response: { "ok" => true, "channel" => "test", "attachments" => [ { "text" => "hi there" } ] }
      )
      expect(
        api.chat_update(channel: channel, ts: ts, attachments: [{text: text}])
      ).to eq("ok" => true, "channel" => "test", "attachments" => [ { "text" => "hi there" } ])
    end

    context "when it gets a Slack error" do
      before do
        expect_post("chat.update", channel: channel, ts: ts, attachments: [{text: text}], as_user: true,
          response: { "ok" => false, error: "invalid_auth" }
        )
      end

      it "raises a RuntimeError" do
        expect {
          api.chat_update(channel: channel, ts: ts, attachments: [{text: text}])
        }.to raise_error("Slack API call to chat.update returned an error: invalid_auth.")
      end
    end

    context "when it gets an HTTP error" do
      before do
        expect_post("chat.update", channel: channel, ts: ts, attachments: [{text: text}], as_user: true,
          raw_response: [ 422, {}, "" ]
        )
      end

      it "raises a RuntimeError" do
        expect {
          api.chat_update(channel: channel, ts: ts, attachments: [{text: text}])
        }.to raise_error("Slack API call to chat.update failed with status code 422: ''. Headers: {}")
      end
    end
  end

  describe "#chat_delete" do
    let(:channel) { "test" }
    let(:ts) { "1234.5678" }

    it "sends the delete" do
      expect_post("chat.delete", channel: channel, ts: ts, as_user: true)
      expect(api.chat_delete(channel: channel, ts: ts)).to eq("ok" => true)
    end

    it "can override as_user" do
      expect_post("chat.delete", channel: channel, ts: ts, as_user: false)
      expect(api.chat_delete(channel: channel, ts: ts, as_user: false)).to eq("ok" => true)
    end

    it "returns whatever it gets back" do
      expect_post("chat.delete", channel: channel, ts: ts, as_user: true,
        response: { "ok" => true, "channel" => "test", "ts" => "1234.5678" }
      )
      expect(api.chat_delete(channel: channel, ts: ts)).to eq(
        "ok" => true, "channel" => "test", "ts" => "1234.5678"
      )
    end

    context "when it gets a Slack error" do
      before do
        expect_post("chat.delete", channel: channel, ts: ts, as_user: true,
          response: { "ok" => false, error: "invalid_auth" }
        )
      end

      it "raises a RuntimeError" do
        expect {
          api.chat_delete(channel: channel, ts: ts)
        }.to raise_error("Slack API call to chat.delete returned an error: invalid_auth.")
      end
    end

    context "when it gets an HTTP error" do
      before do
        expect_post("chat.delete", channel: channel, ts: ts, as_user: true,
          raw_response: [ 422, {}, "" ]
        )
      end

      it "raises a RuntimeError" do
        expect {
          api.chat_delete(channel: channel, ts: ts)
        }.to raise_error("Slack API call to chat.delete failed with status code 422: ''. Headers: {}")
      end
    end
  end

  describe "#groups_list" do
    let(:channel_id) { 'G024BE91L' }
    let(:stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post('https://slack.com/api/groups.list', token: token) do
          [http_status, {}, http_response]
        end
      end
    end

    describe "with a successful response" do
      let(:http_response) do
        MultiJson.dump({
            ok: true,
            groups: [{
                id: 'G024BE91L'
            }]
        })
      end

      it "returns a response with groupss Channel ID's" do
        response = subject.groups_list

        expect(response['groups'].first['id']).to eq(channel_id)
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
        expect { subject.groups_list }.to raise_error(
          "Slack API call to groups.list returned an error: invalid_auth."
        )
      end
    end

    describe "with an HTTP error" do
      let(:http_status) { 422 }
      let(:http_response) { '' }

      it "raises a RuntimeError" do
        expect { subject.groups_list }.to raise_error(
          "Slack API call to groups.list failed with status code 422: ''. Headers: {}"
        )
      end
    end
  end

  describe "#mpim_list" do
    let(:channel_id) { 'G024BE91L' }
    let(:stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post('https://slack.com/api/mpim.list', token: token) do
          [http_status, {}, http_response]
        end
      end
    end

    describe "with a successful response" do
      let(:http_response) do
        MultiJson.dump({
            ok: true,
            groups: [{
                id: 'G024BE91L'
            }]
        })
      end

      it "returns a response with MPIMs Channel ID's" do
        response = subject.mpim_list

        expect(response['groups'].first['id']).to eq(channel_id)
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
        expect { subject.mpim_list }.to raise_error(
          "Slack API call to mpim.list returned an error: invalid_auth."
        )
      end
    end

    describe "with an HTTP error" do
      let(:http_status) { 422 }
      let(:http_response) { '' }

      it "raises a RuntimeError" do
        expect { subject.mpim_list }.to raise_error(
          "Slack API call to mpim.list failed with status code 422: ''. Headers: {}"
        )
      end
    end
  end

   describe "#im_list" do
    let(:channel_id) { 'D024BFF1M' }
    let(:stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post('https://slack.com/api/im.list', token: token) do
          [http_status, {}, http_response]
        end
      end
    end

    describe "with a successful response" do
      let(:http_response) do
        MultiJson.dump({
            ok: true,
            ims: [{
                id: 'D024BFF1M'
            }]
        })
      end

      it "returns a response with IMs Channel ID's" do
        response = subject.im_list

        expect(response['ims'].first['id']).to eq(channel_id)
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
        expect { subject.im_list }.to raise_error(
          "Slack API call to im.list returned an error: invalid_auth."
        )
      end
    end

    describe "with an HTTP error" do
      let(:http_status) { 422 }
      let(:http_response) { '' }

      it "raises a RuntimeError" do
        expect { subject.im_list }.to raise_error(
          "Slack API call to im.list failed with status code 422: ''. Headers: {}"
        )
      end
    end
  end

  describe "#post_message" do
    context "messages" do
      let(:message) { "message text" }
      let(:http_response) { MultiJson.dump({ ok: true }) }
      let(:channel) { "C1234567890" }
      let(:stubs) do
        Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post(
            "https://slack.com/api/chat.postMessage",
            token: token,
            as_user: true,
            channel: channel,
            text: message,
          ) do
            [http_status, {}, http_response]
          end
        end
      end

      context "with a simple message" do
        it "sends the message" do
          response = subject.post_message(channel: channel, text: message)

          expect(response['ok']).to be(true)
        end
      end

      context "with configuration" do
        before do
          allow(config).to receive(:link_names).and_return(true)
          allow(config).to receive(:default_message_arguments).and_return(unfurl_media: false)
        end

        context "and a simple message" do
          def stubs(postmessage_arguments = {})
            Faraday::Adapter::Test::Stubs.new do |stub|
              stub.post(
                "https://slack.com/api/chat.postMessage",
                token: token,
                link_names: 1,
                unfurl_media: false,
                channel: channel,
                text: message
              ) do
                [http_status, {}, http_response]
              end
            end
          end

          it "sends the message with configuration" do
            response = subject.post_message(channel: channel, text: message)

            expect(response['ok']).to be(true)
          end
        end

        context "and a message with arguments" do
          def stubs(postmessage_arguments = {})
            Faraday::Adapter::Test::Stubs.new do |stub|
              stub.post(
                "https://slack.com/api/chat.postMessage",
                token: token,
                link_names: 1,
                unfurl_media: false,
                parse: "none",
                channel: channel,
                text: message
              ) do
                [http_status, {}, http_response]
              end
            end
          end

          it "combines message arguments with configuration" do
            response = subject.post_message(channel: channel, text: message, parse: "none")

            expect(response['ok']).to be(true)
          end
        end

        context "and a message with arguments that override configuration" do
          def stubs(postmessage_arguments = {})
            Faraday::Adapter::Test::Stubs.new do |stub|
              stub.post(
                "https://slack.com/api/chat.postMessage",
                token: token,
                link_names: 1,
                unfurl_media: true,
                channel: channel,
                text: message
              ) do
                [http_status, {}, http_response]
              end
            end
          end

          it "message arguments override configuration" do
            response = subject.post_message(channel: channel, text: message, unfurl_media: true)

            expect(response['ok']).to be(true)
          end
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
          expect { subject.post_message(channel: channel, text: message) }.to raise_error(
            "Slack API call to chat.postMessage returned an error: invalid_auth."
          )
        end
      end

      context "with an HTTP error" do
        let(:http_status) { 422 }
        let(:http_response) { '' }

        it "raises a RuntimeError" do
          expect { subject.post_message(channel: channel, text: message) }.to raise_error(
            "Slack API call to chat.postMessage failed with status code 422: ''. Headers: {}"
          )
        end
      end
    end

    context "attachments" do
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
      let(:channel) { "C1234567890" }
      let(:stubs) do
        Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post(
            "https://slack.com/api/chat.postMessage",
            token: token,
            as_user: true,
            channel: channel,
            attachments: MultiJson.dump([attachment_hash]),
          ) do
            [http_status, {}, http_response]
          end
        end
      end

      context "with a simple text attachment" do
        it "sends the attachment" do
          response = subject.post_message(channel: channel, attachments: [attachment])

          expect(response['ok']).to be(true)
        end
      end

      context "with a different fallback message" do
        let(:attachment) do
          Lita::Adapters::Slack::Attachment.new(attachment_text, fallback: fallback_text)
        end
        let(:fallback_text) { "fallback text" }

        it "sends the attachment" do
          response = subject.post_message(channel: channel, attachments: [attachment])

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
          response = subject.post_message(channel: channel, attachments: [attachment])

          expect(response['ok']).to be(true)
        end
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
          "Slack API call to channels.setTopic failed with status code 422: ''. Headers: {}"
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
