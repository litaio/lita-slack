require 'lita/adapters/slack/chat_service'
require 'lita/adapters/slack/rtm_connection'
require 'forwardable'

module Lita
  module Adapters
    # A Slack adapter for Lita.
    # @api private
    class Slack < Adapter
      # Required configuration attributes.

      #
      # Slack API token.
      #
      # @see https://api.slack.com/web#authentication
      #
      config :token, type: String, required: true
      config :proxy, type: String
      config :default_message_arguments, type: Hash, default: { as_user: true }
      config :parse, type: [String]
      config :link_names, type: [true, false]
      config :unfurl_links, type: [true, false]
      config :unfurl_media, type: [true, false]

      # Provides an object for Slack-specific features.
      def chat_service
        ChatService.new(config, rtm_connection)
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

      # Returns UID(s) in an Array or String for:
      # Channels, MPIMs, IMs
      def roster(target)
        room_roster target.id
      end

      extend Forwardable
      def_delegators :chat_service, :send_messages

      def set_topic(target, topic)
        channel = target.room
        Lita.logger.debug("Setting topic for channel #{channel}: #{topic}")
        api.set_topic(channel, topic)
      end

      def shut_down
        return unless rtm_connection

        rtm_connection.shut_down
        robot.trigger(:disconnected)
      end

      private

      def api
        API.new(config)
      end

      attr_reader :rtm_connection

      def channel_roster(room_id)
        response = api.channels_info room_id
        response['channel']['members']
      end

      # Returns the members of a group, but only can do so if it's a member
      def group_roster(room_id)
        response = api.groups_list
        group = response['groups'].select { |hash| hash['id'].eql? room_id }.first
        group.nil? ? [] : group['members']
      end

      # Returns the members of a mpim, but only can do so if it's a member
      def mpim_roster(room_id)
        response = api.mpim_list
        mpim = response['groups'].select { |hash| hash['id'].eql? room_id }.first
        mpim.nil? ? [] : mpim['members']
      end

      # Returns the user of an im
      def im_roster(room_id)
        response = api.mpim_list
        im = response['ims'].select { |hash| hash['id'].eql? room_id }.first
        im.nil? ? '' : im['user']
      end

      def room_roster(room_id)
        case room_id
        when /^C0/
          channel_roster room_id
        when /^G0/
          # Groups & MPIMs have the same room ID pattern, check both if needed
          roster = group_roster room_id
          roster.empty? ? mpim_roster(room_id) : roster
        when /^D0/
          im_roster room_id
        end
      end
    end

    # Register Slack adapter to Lita
    Lita.register_adapter(:slack, Slack)
  end
end
