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

        # @param dialog The dialog to be shown to the user
        # @param trigger_id The trigger id of a slash command request URL or interactive message
        # @return [void]
        def open_dialog(dialog, trigger_id)
          api.open_dialog(dialog, trigger_id)
        end

        # @param channel The channel containing the message to be deleted
        # @param ts The timestamp of the message
        # @return [void]
        def delete(channel, ts)
          api.delete(channel, ts)
        end

        # @param channel The channel containing the message to be deleted
        # @param ts The timestamp of the message
        # @param attachments [Attachment, Array<Attachment>] An {Attachment} or array of
        #   {Attachment}s to send.
        # @return [void]
        def update_attachments(channel, ts, attachments)
          api.update_attachments(channel, ts, Array(attachments))
        end
      end
    end
  end
end
