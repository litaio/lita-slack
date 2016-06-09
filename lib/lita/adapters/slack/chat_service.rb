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

        # @param target [Lita::Room, Lita::User] A room or user object
        #   indicating where the message should be sent.
        # @param strings [String, Array<String>] A string or strings to send as
        #   text.
        # @param message_arguments [Hash] Message arguments to send to Slack,
        #   governing formatting. Arguments correspond to Slack `chat.postMessage`
        #   arguments and will override `config.default_message_arguments`. See
        #   README for a list of known arguments.
        # @return [Hash] The Slack sent message response, as seen in
        #   https://api.slack.com/methods/chat.postMessage#response . In
        #   particular, `response["ts"]` can be used as the `ts` argument to
        #   update_message and delete_message.
        def send_messages(target, strings=nil, **message_arguments)
          message_arguments[:text] = Array(strings).join("\n") unless strings.nil?
          api.post_message(channel: channel_for(target), **message_arguments)
        end
        alias_method :send_message, :send_messages

        # @param target [Lita::Room, Lita::User] A room or user object
        #   indicating where the message should be sent.
        # @param text [String] The message to /me send.
        # @return [Hash] The Slack sent message response, as seen in
        #   https://api.slack.com/methods/chat.meMessage#response . In
        #   particular, `response["ts"]` can be used as the `ts` argument to
        #   update_message and delete_message.
        def me_message(target, text)
          api.me_message(channel: channel_for(target), text: text)
        end

        # @param target [Lita::Room, Lita::User] A room or user object
        #   indicating where the message should be sent.
        # @param ts [Integer] The timestamp of the message (uniquely identifying it).
        # @param strings [String, Array<String>] A string or strings to send as
        #   text.
        # @param arguments [Hash] Message arguments to send to Slack,
        #   governing formatting. Arguments correspond to Slack `chat.update`
        #   arguments and will override `config.default_message_arguments`. See
        #   README for a list of known arguments.
        # @return [Hash] The Slack sent message response, as seen in
        #   https://api.slack.com/methods/chat.update#response .
        def update_message(target, ts, strings=nil, **arguments)
          arguments[:text] = Array(strings).join("\n") unless strings.nil?
          api.chat_update(channel: channel_for(target), ts: ts, **arguments)
        end

        # @param target [Lita::Room, Lita::User] A room or user object
        #   indicating where the message should be sent.
        # @param ts [Integer] The timestamp of the message (uniquely identifying it).
        # @param arguments [Hash] Extra arguments to send to Slack.
        #   `config.default_message_arguments[:as_user]` will be used if
        #   `as_user` is not specified.
        # @return [Hash] The Slack deleted message response, as seen in
        #   https://api.slack.com/methods/chat.delete#response .
        def delete_message(target, ts, **arguments)
          api.chat_delete(channel: channel_for(target), ts: ts, **arguments)
        end

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
