module Lita
  module Adapters
    class Slack < Adapter
      class SlackChannel
        class << self
          def from_data(channel_data)
            new(
                channel_data['id'],
                channel_data['name'],
                channel_data['created'],
                channel_data['creator'],
                channel_data
            )
          end

          def from_data_array(channels_data)
            channels_data.map { |channel_data| from_data(channel_data) }
          end
        end

        attr_reader :id
        attr_reader :name
        attr_reader :created
        attr_reader :creator
        attr_reader :raw_data

        def initialize(id, name, created, creator, raw_data)
          @id       = id
          @name     = name
          @created  = created
          @creator  = creator
          @raw_data = raw_data
        end
      end
    end
  end
end