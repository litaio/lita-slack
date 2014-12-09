module Lita
  module Adapters
    class Slack < Adapter
      RTMStartResponse = Struct.new(:ims, :users, :websocket_url)
    end
  end
end
