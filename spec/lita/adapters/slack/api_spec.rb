require "spec_helper"

describe Lita::Adapters::Slack::API do
  subject { described_class.new(token, stubs) }

  let(:http_status) { 200 }
  let(:token) { 'abcd-1234567890-hWYd21AmMH2UHAkx29vb5c1Y' }

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

      it "has no error message" do
        response = subject.im_open(user_id)

        expect(response.error).to be_nil
      end
    end

    describe "with a Slack error" do
      let(:http_response) do
        MultiJson.dump({
          ok: false,
          error: 'invalid_auth'
        })
      end

      it "returns a response with an error message" do
        response = subject.im_open(user_id)

        expect(response.error).to eq('invalid_auth')
      end

      it "has no IM ID" do
        response = subject.im_open(user_id)

        expect(response.id).to be_nil
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
end
