module Lita
  module Adapters
    class Slack < Adapter
      class
      ChannelMapping
        def initialize(channels)

          @mapping = {}

          add_mappings(channels)
        end

        def add_mapping(channel)
          mapping[channel.id] = channel.name
        end

        def add_mappings(channels)
          channels.each { |channel| add_mapping(channel) }
        end

        def channel_for(channel_id)
          mapping.fetch(channel_id)
        end

        private

        attr_reader :mapping
      end
    end
  end
end