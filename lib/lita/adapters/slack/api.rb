require 'faraday'

require 'lita/adapters/slack/team_data'
require 'lita/adapters/slack/slack_im'
require 'lita/adapters/slack/slack_user'

module Lita
  module Adapters
    class Slack < Adapter
      class API
        def initialize(config, stubs = nil)
          @token = config[:token]
          @endpoint = config[:endpoint] || "https://slack.com/api"
          @proxy = config[:proxy]
          @stubs = stubs
        end

        def im_open(user_id)
          response_data = call_api("im.open", user: user_id)

          SlackIM.new(response_data["channel"]["id"], user_id)
        end

        def rtm_start
          response_data = call_api("rtm.start")

          TeamData.new(
            SlackIM.from_data_array(response_data["ims"]),
            SlackUser.from_data(response_data["self"]),
            SlackUser.from_data_array(response_data["users"]),
            response_data["url"]
          )
        end

        private

        attr_reader :stubs
        attr_reader :token
        attr_reader :proxy
        attr_reader :endpoint

        def call_api(method, post_data = {})
          response = connection.post(
            "#{endpoint}/#{method}",
            { token: token }.merge(post_data)
          )

          data = parse_response(response, method)

          raise "Slack API call to #{method} returned an error: #{data["error"]}." if data["error"]

          data
        end

        def connection
          if stubs
            Faraday.new { |faraday| faraday.adapter(:test, stubs) }
          else
            options = {}
            if !proxy.nil?
              options = {
                ssl: {verify:false},
                proxy: proxy
              }
            end
            Faraday.new(options)
          end
        end

        def parse_response(response, method)
          unless response.success?
            raise "Slack API call to #{method} failed with status code #{response.status}."
          end

          MultiJson.load(response.body)
        end
      end
    end
  end
end
