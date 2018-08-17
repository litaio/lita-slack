module Lita
  module Adapters
    class Slack < Adapter
      # A struct representing a Slack message source. It has access to
      # extensions of the original message from the source, which enables
      # reacting with emoji or replying in threads.
      #
      # @api public
      class SlackSource < Lita::Source
        def initialize(**kwargs)
          @extensions = kwargs.delete(:extensions)
          super(**kwargs)
        end

        def timestamp
          @extensions[:timestamp]
        end
        
        def thread_ts
          @extensions[:thread_ts]
        end
      end
    end
  end
end
