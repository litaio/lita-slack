require 'eventmachine'
require 'faye/websocket'
require 'multi_json'

require 'lita/adapters/slack/api'
require 'lita/adapters/slack/user_creator'

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

        UserCreator.new.create_users(response.users)

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
        if ws
          log.debug("Closing connection to the Slack Real Time Messaging API.")
          ws.close
        end

        if EM.reactor_running?
          EM.stop
          robot.trigger(:disconnected)
        end
      end

      private

      attr_reader :url
      attr_reader :ws

      def destination_for(target)
        if target.room
          { channel: target.room }
        else
          { user: target.user.id }
        end
      end

      def receive_message(event)
        data = MultiJson.load(event.data)
        type = data["type"]

        case type
        when "hello"
          log.info("Connected to Slack.")
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
          UserCreator.new.create_user(data["user"])
        when "bot_added", "bot_changed"
          log.debug("Updating user data for bot.")
          UserCreator.new.create_user(data["bot"])
        else
          unless data["reply_to"]
            log.debug("#{type} event received from Slack and will be ignored.")
          end
        end
      end

      def rtm_connect
        EM.run do
          log.debug("Connecting to the Slack Real Time Messaging API.")
          @ws = Faye::WebSocket::Client.new(url, nil, ping: 10)

          ws.on(:open) { log.debug("Connected to the Slack Real Time Messaging API.") }
          ws.on(:message) { |event| receive_message(event) }
          ws.on(:close) { log.info("Disconnected from Slack.") }
          ws.on(:error) { |event| log.debug("WebSocket error: #{event.message}") }
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
