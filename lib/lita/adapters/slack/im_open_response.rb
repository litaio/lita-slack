module Lita
  module Adapters
    class Slack < Adapter
      class IMOpenResponse < Struct.new(:error, :id)
        def self.build(data)
          new(
            data.fetch("error") { nil },
            data.fetch("channel") { {} }.fetch("id") { nil }
          )
        end
      end
    end
  end
end

