module Lita
  module Adapters
    class Slack < Adapter
      # @api private
      class SlackSource < Lita::Source
        attr_reader :thread

        def initialize( user: nil, room: nil, private_message: nil, thread: nil )
          super( user: user, room: room, private_message: private_message )
          @thread = thread
        end
      end
    end
  end
end
