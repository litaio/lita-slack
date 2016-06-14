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

        def channels_info(channel_id)
          call_api("channels.info", channel: channel_id)
        end

        def channels_list
          call_api("channels.list")
        end

        def groups_list
          call_api("groups.list")
        end

        def mpim_list
          call_api("mpim.list")
        end

        def im_list
          call_api("im.list")
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

        #
        # Call the Slack API method with the given arguments
        #
        # @param method [String] The Slack API method. e.g. `"chat.postMessage"`.
        #   The full URL posted to will be https://slack.com/api/chat.postMessage.
        # @param arguments [Hash] A Hash of arguments to pass to the Slack API.
        #   Array, Hash and Attachment values will be converted to JSON. `token`
        #   will be passed automatically.
        #
        # @return [Hash] The parsed response, typically `{ "ok" => true, ... }`
        # @raise [RuntimeError] If the server returns a non-200 or returns
        #   `{ "ok" => "false" }`.
        #
        def call_api(method, **arguments)
          # Array and Hash arguments must be JSON-encoded; `nil` arguments will
          # not be passed.
          arguments.each do |key, value|
            case value
            when Array, Hash
              arguments[key] = MultiJson.dump(value)
            when Attachment
              arguments[key] = MultiJson.dump(value.to_hash)
            when nil
              arguments.delete(key)
            end
          end

          response = connection.post(
            "https://slack.com/api/#{method}",
            token: config.token,
            **arguments
          )

          data = parse_response(response, method)

          raise "Slack API call to #{method} returned an error: #{data["error"]}." if data["error"]

          data
        end

        #
        # Get the Slack channel ID for the given Lita target.
        #
        # @param target [Lita::Source, Lita::Room, Lita::User, String] The channel or room
        #   or source you want the channel for.
        # @return [String] The Slack channel or private message ID.
        #
        def channel_for(target)
          case target
          when Lita::Source
            if target.private_message?
              rtm_connection.im_for(target.user.id)
            else
              target.room
            end

          when Lita::Room, Lita::User
            target.id

          else
            target
          end
        end

        private

        attr_reader :stubs
        attr_reader :config

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
            raise "Slack API call to #{method} failed with status code #{response.status}: '#{response.body}'. Headers: #{response.headers}"
          end

          MultiJson.load(response.body)
        end
      end
    end
  end
end
