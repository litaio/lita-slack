require 'lita/adapters/slack/rtm_connection'

module Lita
  module Adapters
    class Slack < Adapter
      # Required configuration attributes.
      config :token, type: String, required: true
      config :proxy, type: String

      # Starts the connection.
      def run
        return if rtm_connection

        @rtm_connection = RTMConnection.build(robot, config)
        rtm_connection.run
      end

      def send_messages(target, messages)
        send_string_messages(target, messages)
        send_complex_messages(target, messages)
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

      def send_string_messages(target, messages)
        return unless rtm_connection

        strings = messages.select { |msg| !msg.respond_to?(:to_slack) }
        rtm_connection.send_messages(channel_for(target), strings)
      end

      def send_complex_messages(target, messages)
        messages = messages.select { |msg| msg.respond_to?(:to_slack) }
        messages.each do |message|
          API.new(config).post_message(channel_for(target), message.to_slack)
        end
      end
    end

    # Register Slack adapter to Lita
    Lita.register_adapter(:slack, Slack)
  end
end
