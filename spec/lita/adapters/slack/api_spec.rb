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

  describe "#call_api" do
    it "with no arguments sends a POST with just a token" do
      stubs.post("http://slack.com/api/x.y", token: token) do
        [200, {}, MultiJson.dump("ok" => true)]
      end
      expect(api.call_api("x.y")).to eq("ok" => true)
    end
    it "with arguments sends the arguments" do
      stubs.post("http://slack.com/api/x.y", token: token, a: 1, b: "hi", c: false, d: true) do
        [200, {}, MultiJson.dump("ok" => true)]
      end
      expect(api.call_api("x.y", a: 1, b: "hi", c: false, d: true)).to eq("ok" => true)
    end
    it "with nil arguments does not send the arguments" do
      stubs.post("http://slack.com/api/x.y", token: token, a: 1, c: false) do
        [200, {}, MultiJson.dump("ok" => true)]
      end
      expect(api.call_api("x.y", a: 1, b: nil, c: false)).to eq("ok" => true)
    end
    it "with hash arguments, JSON-encodes the arguments" do
      stubs.post("http://slack.com/api/x.y", token: token, a: %|{"x":1,"y":2}|) do
        [200, {}, MultiJson.dump("ok" => true)]
      end
      expect(api.call_api("x.y", a: {x: 1, y: 2})).to eq("ok" => true)
    end
    it "with array arguments, JSON-encodes the arguments" do
      stubs.post("http://slack.com/api/x.y", token: token, a: %|["x","y"]|) do
        [200, {}, MultiJson.dump("ok" => true)]
      end
      expect(api.call_api("x.y", a: ["x","y"])).to eq("ok" => true)
    end
    it "with an array of Attachments, JSON-encodes the attachments" do
      stubs.post("http://slack.com/api/x.y", token: token, a: %|[{"fallback":"foo","text":"foo"}]|) do
        [200, {}, MultiJson.dump("ok" => true)]
      end
      attachment = Lita::Adapters::Slack::Attachment.new("foo")
      expect(api.call_api("x.y", a: [attachment])).to eq("ok" => true)
    end
    it "when Slack responds with an error, a RuntimeError is thrown" do
      stubs.post("http://slack.com/api/x.y", token: token) do
        [200, {}, MultiJson.dump("ok" => false, "error" => "invalid_auth") ]
      end
      expect { api.call_api("x.y") }.to raise_error "Slack API call to x.y returned an error: invalid_auth."
    end
    it "when Slack responds with non-200, a RuntimeError is thrown" do
      stubs.post("http://slack.com/api/x.y", token: token) do
        [422, {}, "failed big time"]
      end
      expect { api.call_api("x.y") }.to raise_error "Slack API call to x.y failed with status code 422: 'failed big time'. Headers: {}"
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
