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

        # @param content [String] File contents.
        # @param filename [String] File name.
        # @param filetype [String] Slack file type. Default "text".
        # @param title [String] File title. Default nil.
        # @param initial_comment [String] Initial comment for file. Default nil.
        # @param channels [String] Comma-separated list of channel ids. Default nil.
        # @return [void]
        def send_file_content(content, filename, filetype = "text", title = nil,
          initial_comment = nil, channels = nil)
          api.send_file_content(content, filename, filetype, title,
            initial_comment, channels)
        end
      end
    end
  end
end
