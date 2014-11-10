require 'eventmachine'
require 'faraday'
require 'faye/websocket'
require 'multi_json'

module Lita
  module Adapters
    class Slack < Adapter
      # Base URL for all Slack API requests.
      API_URL = 'https://slack.com/api/'.freeze

      # Types of messages Lita should dispatch to handlers.
      SUPPORTED_MESSAGE_SUBTYPES = %w(
        bot_message
        me_message
      )

      # Required configuration attributes.
      config :token, type: String, required: true

      # Starts the connection.
      def run
        log.debug("Getting connection information for the Slack Real Time Messaging API.")
        response = call_api('rtm.start', token: config.token)

        return connection_error(response["error"]) unless response["ok"]

        create_users(response["users"])

        @url = response["url"]
        run_loop
      end

      def send_messages(target, strings)
        if target.room
          case target.room[0].upcase
          when ?C
            strings.each do |string|
              @ws.send MultiJson.dump({
                id: 1,
                type: "message",
                channel: target.room,
                text: string
              })
            end
          when ?G
            strings.each do |string|
              @ws.send MultiJson.dump({
                id: 1,
                type: "message",
                channel: target.room,
                text: string
              })
            end
          end
        else
          strings.each do |string|
            @ws.send MultiJson.dump({
              id: 1,
              type: "message",
              user: target.user.id,
              text: string
            })
          end
        end
      end

      def shut_down
        EM.stop
        log.debug("Disconnected from Slack.")
        robot.trigger(:disconnected)
      end

      private

      def call_api(method, post_data = {})
        log.debug("Calling Slack API method: #{method}.")
        response = Faraday.post("#{API_URL}#{method}", post_data)
        MultiJson.load(response.body)
      end

      def connection_error(error)
        message = case error
        when "not_authed"
          "No authentication token was provided to Slack."
        when "invalid_auth"
          "The Slack authentication token provided was not valid."
        when "account_inactive"
          "The user or team associated with the provided authentication token has been deleted."
        else
          "An unknown error connecting to Slack."
        end

        raise message
      end

      def create_user(user_data)
        User.create(user_data["id"], name: real_name(user_data), mention_name: user_data["name"])
      end

      def create_users(users_data)
        users_data.each { |user_data| create_user(user_data) }
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
          @ws = Faye::WebSocket::Client.new(@url)
          @ws.on(:message) { |event| receive_message(event) }
          @ws.on(:close) { |event| shut_down }
        end
      rescue Interrupt
        if defined?(@ws)
          log.debug("Closing connection to the Slack Real Time Messaging API.")
          @ws.close
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
