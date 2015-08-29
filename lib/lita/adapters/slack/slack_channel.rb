module Lita
  module Adapters
    class Slack < Adapter
      # A struct representing a Slack channel, group, or IM.
      # @api public
      class SlackChannel
        class << self
          # @api private
          def from_data(channel_data)
            new(
                channel_data['id'],
                channel_data['name'],
                channel_data['created'],
                channel_data['creator'],
                channel_data
            )
          end

          # @api private
          def from_data_array(channels_data)
            channels_data.map { |channel_data| from_data(channel_data) }
          end
        end

        # @return [String] The channel's unique ID.
        attr_reader :id
        # @return [String] The human-readable name for the channel.
        attr_reader :name
        # @return [String] A timestamp indicating when the channel was created.
        attr_reader :created
        # @return [String] The unique ID of the user who created the channel.
        attr_reader :creator
        # @return [Hash] The raw channel data received from Slack, including many more fields.
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
