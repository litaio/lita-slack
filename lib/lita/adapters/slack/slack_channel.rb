module Lita
  module Adapters
    class Slack < Adapter
      class SlackChannel
        class << self
          def from_data(channel_data)
            new(
                channel_data['id'],
                channel_data['name']
            )
          end

          def from_data_array(channels_data)
            channels_data.map { |channel_data| from_data(channel_data) }
          end
        end

        attr_reader :id
        attr_reader :name

        def initialize(id, name)
          @id = id
          @name = name
        end
      end
    end
  end
end
