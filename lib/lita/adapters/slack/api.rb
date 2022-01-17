require 'faraday'

require_relative 'team_data'
require_relative 'slack_im'
require_relative 'slack_user'
require_relative 'slack_channel'

module Lita
  module Adapters
    class Slack < Adapter
      # @api private
      class API
        def initialize(config, stubs = nil)
          @config = config
          @stubs = stubs
          @post_message_config = {}
          @post_message_config[:parse] = config.parse unless config.parse.nil?
          @post_message_config[:link_names] = config.link_names ? 1 : 0 unless config.link_names.nil?
          @post_message_config[:unfurl_links] = config.unfurl_links unless config.unfurl_links.nil?
          @post_message_config[:unfurl_media] = config.unfurl_media unless config.unfurl_media.nil?
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

        def user_info( user_id )
          call_api("users.info", user: user_id)
        end

        def send_attachments(room_or_user, attachments)
          call_api(
            "chat.postMessage",
            as_user: true,
            channel: room_or_user.id,
            attachments: MultiJson.dump(attachments.map(&:to_hash)),
          )
        end

        def send_messages(channel_id, messages, additional_payload = {})
          data = {
            channel: channel_id,
            as_user: true,
            text: messages.join("\n"),
          }.merge(post_message_config)
           .merge(additional_payload)

          call_api( "chat.postMessage", **data )
        end

        def set_topic(channel, topic)
          call_api("channels.setTopic", channel: channel, topic: topic)
        end

        def rtm_connect
          response_data = call_api("rtm.connect")

          raise RuntimeError, response_data["error"] if response_data["ok"] != true

          TeamData.new(
            response_data["team"]["id"],
            response_data["team"]["name"],
            response_data["team"]["domain"],
            SlackUser.from_data(response_data["self"]),
            response_data["url"],
          )
        end

        private

        attr_reader :stubs
        attr_reader :config
        attr_reader :post_message_config

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
            raise "Slack API call to #{method} failed with status code #{response.status}: '#{response.body}'. Headers: #{response.headers}"
          end

          MultiJson.load(response.body)
        end
      end
    end
  end
end
