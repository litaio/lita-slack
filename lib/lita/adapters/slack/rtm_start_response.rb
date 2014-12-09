module Lita
  module Adapters
    class Slack < Adapter
      RTMStartResponse = Struct.new(:ims, :self, :users, :websocket_url)
    end
  end
end
