module Lita
  module Adapters
    class Slack < Adapter
      # @api private
      class RoomCreator
        class << self
          def create_room(channel, robot)
            log.debug("xtra - create_room : #{channel.id} : #{channel.name}")
            Lita::Room.create_or_update(channel.id, name: channel.name)

            robot.trigger(:slack_channel_created, slack_channel: channel)
          end

          def create_rooms(channels, robot)
            log.debug('xtra - create_rooms')
            channels.each { |channel| create_room(channel, robot) }
          end

          def log
            Lita.logger
          end
        end
      end
    end
  end
end
