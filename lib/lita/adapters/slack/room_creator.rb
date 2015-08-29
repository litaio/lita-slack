module Lita
  module Adapters
    class Slack < Adapter
      # @api private
      class RoomCreator
        class << self
          def create_room(channel, robot)
            Lita::Room.create_or_update(channel.id, name: channel.name)

            robot.trigger(:slack_channel_created, slack_channel: channel)
          end

          def create_rooms(channels, robot)
            channels.each { |channel| create_room(channel, robot) }
          end
        end
      end
    end
  end
end
