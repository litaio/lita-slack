module Lita
  module Adapters
    class Slack < Adapter
      TeamData = Struct.new(:ims, :self, :users, :websocket_url)
    end
  end
end
