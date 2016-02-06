require 'lita/adapters/slack/reaction'

module Lita
  module Adapters
    class Slack < Adapter
      # @api private
      class MessageHandler
        def initialize(robot, robot_id, data)
          @robot = robot
          @robot_id = robot_id
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
          when "channel_created", "channel_rename", "group_rename"
            handle_channel_change
          when "error"
            handle_error
          when "reaction_added", "reaction_removed"
            handle_reaction
          else
            handle_unknown
          end
        end

        private

        attr_reader :data
        attr_reader :robot
        attr_reader :robot_id
        attr_reader :type

        def body
          normalized_message = if data["text"]
            data["text"].sub(/^\s*<@#{robot_id}>/, "@#{robot.mention_name}")
          end

         normalized_message = remove_formatting(normalized_message) unless normalized_message.nil?

          attachment_text = Array(data["attachments"]).map do |attachment|
            attachment["text"] || attachment["fallback"]
          end

          ([normalized_message] + attachment_text).compact.join("\n")
        end

        def remove_formatting(message)
          # https://api.slack.com/docs/formatting
          message = message.gsub(/
              <                    # opening angle bracket
              (?<type>[@#!])?      # link type
              (?<link>[^>|]+)      # link
              (?:\|                # start of |label (optional)
                  (?<label>[^>]+)  # label
              )?                   # end of label
              >                    # closing angle bracket
              /ix) do
            link  = Regexp.last_match[:link]
            label = Regexp.last_match[:label]

            case Regexp.last_match[:type]
              when '@'
                if label
                  label
                else
                  user = User.find_by_id(link)
                  if user
                    "@#{user.mention_name}"
                  else
                    "@#{link}"
                  end
                end

              when '#'
                if label
                  label
                else
                  channel = Lita::Room.find_by_id(link)
                  if channel
                    "\##{channel.name}"
                  else
                    "\##{link}"
                  end
                end

              when '!'
                "@#{link}" if ['channel', 'group', 'everyone'].include? link
              else
                link = link.gsub /^mailto:/, ''
                if label && !(link.include? label)
                  "#{label} (#{link})"
                else
                  label == nil ? link : label
                end
            end
          end
          message.gsub('&lt;', '<')
                 .gsub('&gt;', '>')
                 .gsub('&amp;', '&')

        end

        def channel
          data["channel"]
        end

        def dispatch_message(user)
          source = Source.new(user: user, room: channel)
          source.private_message! if channel && channel[0] == "D"
          message = Message.new(robot, body, source)
          message.command! if source.private_message?
          message.extensions[:slack] = { timestamp: data["ts"] }
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
          UserCreator.create_user(SlackUser.from_data(data["bot"]), robot, robot_id)
        end

        def handle_channel_change
          log.debug("Updating channel data.")
          RoomCreator.create_room(SlackChannel.from_data(data["channel"]), robot)
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

        def handle_reaction
          log.debug "#{type} event received from Slack"

          # find or create user
          user = User.find_by_id(data["user"]) || User.create(data["user"])

          # avoid processing reactions added/removed by self
          return if from_self?(user)

          # create and configure the source
          item_channel = data['item']['channel']
          source = Source.new(user: user, room: data['item']['channel'])
          source.private_message! if item_channel && item_channel[0] == "D"

          # extract attributes from data received
          name = data["reaction"]
          item = data["item"]
          event = data["type"] == "reaction_added" ? "added" : "removed"

          # create and configure a Reaction object
          reaction = Reaction.new(robot, name, item, source, event)
          reaction.extensions[:slack] = { timestamp: data["event_ts"] }

          # dispatch reaction
          robot.receive(reaction)
        end

        def handle_unknown
          unless data["reply_to"]
            log.debug("#{type} event received from Slack and will be ignored.")
          end
        end

        def handle_user_change
          log.debug("Updating user data.")
          UserCreator.create_user(SlackUser.from_data(data["user"]), robot, robot_id)
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
