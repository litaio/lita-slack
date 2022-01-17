module Lita
  module Adapters
    # @api private
    class Slack < Adapter
      TeamData = Struct.new(:id, :name, :domain, :self, :websocket_url)
    end
  end
end
