module Lita
  module Adapters
    class Slack < Adapter
      class MessageHandler
        def initialize(robot, data)
          @robot = robot
          @data = data
          @type = data["type"]
        end

        def handle
          case type
          when "hello"
            handle_hello
          when "message"
            handle_message
          when "user_change", "team_join"
            handle_user_change
          when "bot_added", "bot_changed"
            handle_bot_change
          when "error"
            handle_error
          else
            handle_unknown
          end
        end

        private

        attr_reader :data
        attr_reader :robot
        attr_reader :type

        def dispatch_message(user)
          source = Source.new(user: user, room: data["channel"] || data["group"])
          message = Message.new(robot, data["text"], source)
          log.debug("Dispatching message to Lita from #{user.id}.")
          robot.receive(message)
        end

        def from_self?(user)
          if data["subtype"] == "bot_message"
            robot_user = User.find_by_name(robot.name)

            robot_user && robot_user.id == user.id
          end
        end

        def handle_bot_change
          log.debug("Updating user data for bot.")
          UserCreator.create_user(data["bot"])
        end

        def handle_error
          error = data["error"]
          code = error["code"]
          message = error["msg"]
          log.error("Error with code #{code} received from Slack: #{message}")
        end

        def handle_hello
          log.info("Connected to Slack.")
          robot.trigger(:connected)
        end

        def handle_message
          return unless supported_subtype?

          user = User.find_by_id(data["user"]) || User.create(data["user"])

          return if from_self?(user)

          dispatch_message(user)
        end

        def handle_unknown
          unless data["reply_to"]
            log.debug("#{type} event received from Slack and will be ignored.")
          end
        end

        def handle_user_change
          log.debug("Updating user data.")
          UserCreator.create_user(data["user"])
        end

        def log
          Lita.logger
        end

        # Types of messages Lita should dispatch to handlers.
        def supported_message_subtypes
          %w(bot_message me_message)
        end

        def supported_subtype?
          subtype = data["subtype"]

          if subtype
            supported_message_subtypes.include?(subtype)
          else
            true
          end
        end
      end
    end
  end
end
