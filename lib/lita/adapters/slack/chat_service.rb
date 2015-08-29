require "lita/adapters/slack/attachment"

module Lita
  module Adapters
    class Slack < Adapter
      class ChatService
        attr_accessor :api

        def initialize(adapter)
          self.api = API.new(adapter.config)
        end

        def send_attachments(target, attachments)
          api.send_attachments(target, Array(attachments))
        end
        alias_method :send_attachment, :send_attachments
      end
    end
  end
end
