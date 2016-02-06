module Lita
  module Adapters
    class Slack < Adapter
      class Reaction < Message
        # name and item attributes of the Reaction - following Slack convention
        attr_reader :name, :item, :event

        # treat name of Reaction equivalent to body of Message
        alias_method :body, :name

        def initialize(robot, name, item, source, event)
          @item = item
          @name = name
          @event = event
          super(robot, body, source)
        end
      end
    end
  end
end