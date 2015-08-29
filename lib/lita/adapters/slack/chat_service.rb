module Lita
  module Adapters
    class Slack < Adapter
      class ChatService
        def initialize(adapter)
          self.adapter = adapter
        end

        private

        attr_accessor :adapter
      end
    end
  end
end
