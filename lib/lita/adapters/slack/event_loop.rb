require 'eventmachine'

module Lita
  module Adapters
    class Slack < Adapter
      class EventLoop
        class << self
          def run
            EM.run { yield }
          end

          def safe_stop
            EM.stop if EM.reactor_running?
          end
        end
      end
    end
  end
end
