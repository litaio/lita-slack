module Lita
  module Adapters
    # @api private
    class Slack < Adapter
      TeamData = Struct.new(:ims, :self, :users, :channels, :websocket_url)
    end
  end
end
