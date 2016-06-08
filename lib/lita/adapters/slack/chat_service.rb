require "lita/adapters/slack/attachment"

module Lita
  module Adapters
    class Slack < Adapter
      # Slack-specific features made available to +Lita::Robot+.
      # @api public
      # @since 1.6.0
      class ChatService
        attr_accessor :api
        attr_reader :rtm_connection

        # @param config [Lita::Configuration] The adapter's configuration data.
        def initialize(config, rtm_connection=nil)
          self.api = API.new(config)
          @rtm_connection = rtm_connection
        end

        # @param target [Lita::Room, Lita::User] A room or user object indicating where the
        #   attachment should be sent.
        # @param strings [String, Array<String>] A string or strings to send as
        #   text.
        # @param message_arguments [Hash] Message arguments to send to Slack,
        #   governing formatting. Arguments correspond to Slack `chat.postMessage`
        #   arguments and will override `config.default_message_arguments`. See
        #   README for a list of known arguments.
        # @return [void]
        def send_messages(target, strings=nil, **message_arguments)
          message_arguments[:text] = Array(strings).join("\n") unless strings.nil?
          api.post_message(channel: channel_for(target), **message_arguments)
        end
        alias_method :send_message, :send_messages

        # @param target [Lita::Source, Lita::Room, Lita::User] A room or user
        #        object indicating where the attachment should be sent.
        # @param attachments [Attachment, Hash, Array<Attachment>, Hash<String>] An {Attachment} or array of
        #   {Attachment}s to send.
        # @return [void]
        def send_attachments(target, attachments, **message_arguments)
          message_arguments[:attachments] = Array(attachments)
          api.post_message(channel: channel_for(target), **message_arguments)
        end
        alias_method :send_attachment, :send_attachments

        private

        def channel_for(target)
          case target
          when Lita::Source
            if target.private_message?
              rtm_connection.im_for(target.user.id)
            else
              target.room
            end

          when Lita::Room, Lita::User
            target.id

          else
            target
          end
        end
      end
    end
  end
end
