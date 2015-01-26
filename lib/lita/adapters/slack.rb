require 'lita/adapters/slack/rtm_connection'

module Lita
  module Adapters
    class Slack < Adapter
      # Required configuration attributes.
      config :token, type: String, required: true
      config :endpoint, type: String, default: "https://slack.com/api"
      config :proxy, type: String

      # Starts the connection.
      def run
        return if rtm_connection

        @rtm_connection = RTMConnection.build(robot, config)
        rtm_connection.run
      end

      def send_messages(target, strings)
        return unless rtm_connection

        rtm_connection.send_messages(channel_for(target), strings)
      end

      def shut_down
        return unless rtm_connection

        rtm_connection.shut_down
        robot.trigger(:disconnected)
      end

      private

      attr_reader :rtm_connection

      def channel_for(target)
        if target.room
          target.room
        else
          rtm_connection.im_for(target.user.id)
        end
      end
    end

    # Register Slack adapter to Lita
    Lita.register_adapter(:slack, Slack)
  end
end
