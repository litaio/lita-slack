require "lita/adapters/slack/attachment"

module Lita
  module Adapters
    class Slack < Adapter
      # Slack-specific features made available to +Lita::Robot+.
      # @api public
      # @since 1.6.0
      class ChatService
        attr_accessor :api

        # @param config [Lita::Configuration] The adapter's configuration data.
        def initialize(config)
          self.api = API.new(config)
        end

        # @param target [Lita::Room, Lita::User] A room or user object indicating where the
        #   attachment should be sent.
        # @param attachments [Attachment, Array<Attachment>] An {Attachment} or array of
        #   {Attachment}s to send.
        # @return [void]
        def send_attachments(target, attachments)
          api.send_attachments(target, Array(attachments))
        end
        alias_method :send_attachment, :send_attachments

        # @param message [Lita::Message] A message to add a reaction to
        # @param name [String] Name of the emoji reaction to add
        # @since 1.8.2
        # @return [void]
        def add_reaction(message, name)
          api.add_reaction(message, name)
        end

        # @param message [Lita::Message] A message to remove a reaction from
        # @param name [String] Name of the emoji reaction to remove
        # @since 1.8.2
        # @return [void]
        def remove_reaction(message, name)
          api.remove_reaction(message, name)
        end
      end
    end
  end
end
