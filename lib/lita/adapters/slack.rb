require 'lita/adapters/slack/chat_service'
require 'lita/adapters/slack/rtm_connection'

module Lita
  module Adapters
    # A Slack adapter for Lita.
    # @api private
    class Slack < Adapter
      # Required configuration attributes.
      config :token, type: String, required: true
      config :proxy, type: String
      config :parse, type: String

      # Provides an object for Slack-specific features.
      def chat_service
        ChatService.new(config)
      end

      def mention_format(name)
        "@#{name}"
      end

      # Starts the connection.
      def run
        return if rtm_connection

        @rtm_connection = RTMConnection.build(robot, config)
        rtm_connection.run
      end

      def send_messages(target, strings)
        api = API.new(config)
        api.send_messages(channel_for(target), strings)
      end

      def set_topic(target, topic)
        channel = target.room
        Lita.logger.debug("Setting topic for channel #{channel}: #{topic}")
        API.new(config).set_topic(channel, topic)
      end

      def shut_down
        return unless rtm_connection

        rtm_connection.shut_down
        robot.trigger(:disconnected)
      end

      private

      attr_reader :rtm_connection

      def channel_for(target)
        if target.private_message?
          rtm_connection.im_for(target.user.id)
        else
          target.room
        end
      end
    end

    # Register Slack adapter to Lita
    Lita.register_adapter(:slack, Slack)
  end
end
