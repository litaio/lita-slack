require 'eventmachine'
require 'faye/websocket'
require 'multi_json'

require 'lita/adapters/slack/api'

module Lita
  module Adapters
    class Slack < Adapter
      # Types of messages Lita should dispatch to handlers.
      SUPPORTED_MESSAGE_SUBTYPES = %w(
        bot_message
        me_message
      )

      # Required configuration attributes.
      config :token, type: String, required: true

      # Starts the connection.
      def run
        response = API.new(config.token).rtm_start

        raise response.error if response.error

        create_users(response.users)

        rtm_connect(response.ws_url)
      end

      def send_messages(target, strings)
        destination = destination_for(target)

        strings.each do |string|
          ws.send MultiJson.dump({
            id: 1,
            type: 'message',
            text: string
          }.merge(destination))
        end
      end

      def shut_down
        return unless EM.reactor_running?

        if defined?(ws)
          log.debug("Closing connection to the Slack Real Time Messaging API.")
          ws.close
        end

        EM.stop
        log.debug("Disconnected from Slack.")
        robot.trigger(:disconnected)
      end

      private

      attr_reader :url
      attr_reader :ws

      def create_user(user_data)
        User.create(user_data["id"], name: real_name(user_data), mention_name: user_data["name"])
      end

      def create_users(users_data)
        users_data.each { |user_data| create_user(user_data) }
      end

      def destination_for(target)
        if target.room
          { channel: target.room }
        else
          { user: target.user.id }
        end
      end

      def real_name(user_data)
        real_name = user_data["real_name"]
        real_name.size > 0 ? real_name : user_data["name"]
      end

      def receive_message(event)
        data = MultiJson.load(event.data)
        type = data["type"]

        case type
        when "hello"
          log.debug("Connected to the Slack Real Time Messaging API.")
          robot.trigger(:connected)
        when "message"
          should_dispatch = true

          if data["subtype"] && !SUPPORTED_MESSAGE_SUBTYPES.include?(data["subtype"])
            should_dispatch = false
          end

          user = User.find_by_id(data["user"]) || User.create(data["user"])

          if data["subtype"] == "bot_message"
            robot_user = User.find_by_name(robot.name)

            if robot_user && robot_user.id == user.id
              should_dispatch = false
            end
          end

          if should_dispatch
            source = Source.new(user: user, room: data["channel"] || data["group"])
            message = Message.new(robot, data["text"], source)
            log.debug("Dispatching message to Lita from #{user.id}.")
            robot.receive(message)
          end
        when "user_change", "team_join"
          log.debug("Updating user data.")
          create_user(data["user"])
        when "bot_added", "bot_changed"
          log.debug("Updating user data for bot.")
          create_user(data["bot"])
        else
          unless data["reply_to"]
            log.debug("#{type} event received from Slack and will be ignored.")
          end
        end
      end

      def run_loop
        EM.run do
          log.debug("Connecting to the Slack Real Time Messaging API.")
          @ws = Faye::WebSocket::Client.new(url)
          ws.on(:message) { |event| receive_message(event) }
          ws.on(:close) { |event| shut_down }
        end
      end
    end

    # Register Slack adapter to Lita
    Lita.register_adapter(:slack, Slack)
  end
end

Lita.register_handler(:echo) do
  route /(.+)/i do |response|
    response.reply response.matches
  end
end
