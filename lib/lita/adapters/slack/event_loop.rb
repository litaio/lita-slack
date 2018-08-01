require 'eventmachine'

module Lita
  module Adapters
    class Slack < Adapter
      # @api private
      class EventLoop
        class << self
          def defer
            EM.defer { yield }
          end

          def run
            EM.run { yield }
          end

          def safe_stop
            EM.stop if running?
          end

          def running?
            EM.reactor_running? && !EM.stopping?
          end
        end
      end
    end
  end
end
