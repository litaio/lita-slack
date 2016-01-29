require 'faraday'

require 'lita/adapters/slack/team_data'
require 'lita/adapters/slack/slack_im'
require 'lita/adapters/slack/slack_user'
require 'lita/adapters/slack/slack_channel'

module Lita
  module Adapters
    class Slack < Adapter
      # @api private
      class API
        def initialize(config, stubs = nil)
          @config = config
          @stubs = stubs
        end

        def im_open(user_id)
          response_data = call_api("im.open", user: user_id)

          SlackIM.new(response_data["channel"]["id"], user_id)
        end

        def send_attachments(room_or_user, attachments)
          call_api(
            "chat.postMessage",
            as_user: true,
            channel: room_or_user.id,
            attachments: MultiJson.dump(attachments.map(&:to_hash)),
          )
        end

        def send_messages(channel_id, messages)
          call_api(
            "chat.postMessage",
            as_user: true,
            channel: channel_id,
            text: messages.join("\n"),
            parse: config.parse,
          )
        end

        def set_topic(channel, topic)
          call_api("channels.setTopic", channel: channel, topic: topic)
        end

        def rtm_start
          response_data = call_api("rtm.start")

          TeamData.new(
            SlackIM.from_data_array(response_data["ims"]),
            SlackUser.from_data(response_data["self"]),
            SlackUser.from_data_array(response_data["users"]),
            SlackChannel.from_data_array(response_data["channels"]) +
              SlackChannel.from_data_array(response_data["groups"]),
            response_data["url"],
          )
        end

        private

        attr_reader :stubs
        attr_reader :config

        def call_api(method, post_data = {})
          response = connection.post(
            "https://slack.com/api/#{method}",
            { token: config.token }.merge(post_data)
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
            unless config.proxy.nil?
              options = { proxy: config.proxy }
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
