module Lita
  module Adapters
    class Slack < Adapter
      class RTMStartResponse < Struct.new(:error, :ims, :users, :websocket_url)
        def self.build(data)
          new(
            data["error"],
            data["ims"],
            data["users"],
            data["url"]
          )
        end
      end
    end
  end
end
