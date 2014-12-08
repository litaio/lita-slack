require 'lita/adapters/slack/api'
require 'lita/adapters/slack/im_mapping'
require 'lita/adapters/slack/rtm_connection'
require 'lita/adapters/slack/user_creator'

module Lita
  module Adapters
    class Slack < Adapter
      MAX_MESSAGE_CHARS = 4000

      # Required configuration attributes.
      config :token, type: String, required: true

      def initialize(robot)
        super

        @api = API.new(config.token)
        @im_mapping = IMMapping.new(api)
      end

      # Starts the connection.
      def run
        return if rtm_connection

        response = api.rtm_start

        raise response.error if response.error

        populate_data(response)

        @rtm_connection = RTMConnection.new(response.websocket_url)
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

      attr_reader :api
      attr_reader :im_mapping
      attr_reader :rtm_connection

      def channel_for(target)
        if target.room
          target.room
        else
          im_mapping.im_for(target.user.id)
        end
      end

      def populate_data(data)
        UserCreator.new.create_users(data.users)
        im_mapping.add_mappings(data.ims)
      end
    end

    # Register Slack adapter to Lita
    Lita.register_adapter(:slack, Slack)
  end
end
