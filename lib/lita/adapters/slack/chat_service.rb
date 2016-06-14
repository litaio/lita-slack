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

        #
        # Send a message to Slack.
        #
        # @param target [Lita::Source, Lita::Room, Lita::User, String] A Lita
        #   source, room or user object, or a Slack channel ID, indicating where
        #   the message should be sent.
        # @param text [String] The text of the message. Either text or attachments
        #   is required.
        # @param attachments [Array<Hash, Attachment>] A list of attachments to
        #   the message. Either text or attachments is required. Each attachment
        #   must be either an attachment object or a Hash of the form specified
        #   in https://api.slack.com/docs/attachments#attachment_structure.
        #
        #   `pretext`, `title`, `text`, field `value` and `footer` are affected
        #   by `parse` and `link_names`.
        #
        #   Markdown is not enabled in any field by default. See the `mrkdwn_in`
        #   option to control markdown formatting in pretext, text
        #   and fields. Slack links like `<https://google.com|Google>` are
        #   *always* enabled in pretext, title, text, field values and footer,
        #   and never enabled in author_name and field titles. Links in
        #   attachments are never unfurled.
        # @option attachments [String] :fallback Required plain-text summary of
        #   the attachment.
        # @option attachments [:good, :warning, :danger, String] :color The
        #   color of the left border of the attachment. good=green,
        #   warning=yellow, danger=red. Pass `"#<hex>"` for an arbitrary color
        #   (e.g. `"#439FE0"`).
        # @option mrkdwn_in [Array<String>] :mrkdwn_in The list of elements with
        #   markdown in them. Passing `["pretext"]` will enable markdown in
        #   `pretext` but not in `text`. Possible values include `"pretext"`,
        #   `"text"` and `"fields"` (which will affect only field values, not
        #   field titles). This does not affect Slack API links like
        #   `<https://google.com|Google>`. By default, markdown is not enabled
        #   anywhere.
        # @option attachments [String] :pretext The text to show before the
        #   attachment (will not be inside the color bar).
        # @option attachments [String] :author_name The author's full name to
        #   show at the top of the message, inside the color border.
        # @option attachments [String] :author_link A valid URL that will
        #   hyperlink the `author_name` text.
        # @option attachments [String] :author_icon A valid URL that displays a
        #   small 16x16px image to the left of the `author_name` text.
        # @option attachments [String] :title A title to display in larger,
        #   bold text at the top of the attachment, inside the color border).
        # @option attachments [String] :title_link A URL for the `title` to
        #   link to.
        # @option attachments [String] :text The text of the attachment.
        # @option attachments [Array<Hash>] :fields A list of fields to display,
        #  each of which is a Hash with `:title` and `:value` fields to display
        #  the name and value of the field, and an optional `:short` to indicate
        #  that the `value` is short enough to display side-by-side with other
        #  values. e.g. `[ { "title": "ID", value: "100", short: true }]`
        # @option attachments [String] :image_url A valid URL to a GIF, JPEG,
        #  PNG or BMP image that will be shown inside the attachment. Images
        #  larger than 400x500px will be resized down, maintaining aspect ratio.
        # @option attachments [String] :thumb_url A valid URL to a GIF, JPEG,
        #  PNG or BMP image that will be shown to the right of the attachment
        #  as a thumbnail. Images larger than 75x75px will be resized down,
        #  maintaining aspect ratio. Images must be smaller than 500KB.
        # @option attachments [String] :footer Brief context for the attachment
        #  that will be displayed below it, inside the color bar. Maximum
        #  300 characters.
        # @option attachments [String] :footer_icon A valid URL to a small icon
        #  to display next to the `footer`. Icons will be resized to 16x16px.
        # @option attachments [String] :ts Timestamp for the events described in the
        #  attachment, in UTC epoch time (e.g. `Time.now.utc.to_i`). Displayed
        #  to the right of the `footer`, inside the color bar.
        # @param parse ["none", "full"] Governs what formatting you can put in your
        #   messages and attachments.
        #
        #   Setting `parse` to `"none"` lets you pass links and directives with
        #   angle brackets `<https://google.com|Google>`, and automatically
        #   finds and linkifies URLs in the message (like `https://google.com`).
        #   See the [Slack formatting docs](https://api.slack.com/docs/formatting)
        #   for more information on the subject. It also turns off
        #   `unfurl_media`.
        #
        #   Setting `parse` to `"full"` disables angle bracket links and
        #   directives, instead showing the angle brackets to the user (so
        #   `<https://google.com|Google>` prints out as `<https://google.com|Google>`),
        #   and turns on `link_names`. (NOTE: contrary to Slack documentation,
        #   setting `parse` to `"full"` does not appear to turn on `unfurl_links`.)
        #
        #   By default, angle brackets are ignored like in `full` but
        #   `link_names` remains off.
        # @param mrkdwn [0] When set to `0`, disables Slack-flavored markdown
        #   such as bold and italics in the message.
        # @param link_names [1] When set to `1`, tells Slack to find and linkify
        #   channel and usernames such as @user and #channel in messages and
        #   attachments. Slack has this off by default, but if `parse` is
        #   `"full"`, it's turned on.
        # @param unfurl_links [Boolean] When set to `true`, Slack will find URLs
        #   in your message that point to non-media stuff (like Google or
        #   Github) and generate an attachment automatically for them. Defaults
        #   to `false`.
        # @param unfurl_media [Boolean] When set to `true`, Slack will find URLs
        #   in messages and attachments that point to images, video, sound, etc.
        #   and [generate attachments for
        #   them](https://api.slack.com/docs/unfurling) automatically. This
        #   defaults to `false`, but is `parse` is `"full"`, it's turned on.
        # @param as_user [Boolean, nil]  Determines whether the bot posts as
        #   an authenticated user. If set to `true`, `username`, `icon_emoji`
        #   and `icon_url` are ignored and the actual bot user's username,
        #   icon_emoji and icon_url are used. Posting as a bot can be useful if
        #   you want to change the bot's icon on a per-message basis. If you
        #   pass `nil`, `as_user` will not be sent to Slack and Slack will guess
        #   a value for you. Defaults to `true`.
        # @param username [String] The display name for the user (not the
        #   `@nickname`, the full name). Defaults to the bot's Slack-configured
        #   username.
        # @param icon_emoji [String] An emoji for the Bot's post (e.g. `:lol:`).
        #   Defaults to the bot's Slack-configured icon emoji.
        # @param icon_url [String] The URL to an image for the Bot's icon.
        #   Defaults to the bot's Slack-configured icon.
        #
        # @return [Hash] The sent message response, as seen in
        #   https://api.slack.com/methods/chat.postMessage#response. In
        #   particular, `response["ts"]` can be used as the `ts` argument to
        #   update_message and delete_message.
        #
        # @example Sending a message
        #
        # ```ruby
        # robot.chat_service.post_message(my_room,
        #   text: "hi",
        #   attachments: [
        #     { text: "attached", fallback: "fallback" }
        #   ])
        # ==>
        #   {"ok"=>true,
        #    "channel"=>"C134JG51Q",
        #    "ts"=>"1465845792.000008",
        #    "message"=>
        #     {"text"=>"hi",
        #      "username"=>"bot",
        #      "bot_id"=>"B134DKK08",
        #      "attachments"=>
        #       [{"text"=>"attached", "id"=>1, "fallback"=>"fallback"}],        #      "type"=>"message",
        #      "subtype"=>"bot_message",
        #      "ts"=>"1465845792.000008"}}
        # ```
        #
        def post_message(target,
            text: nil,
            attachments: nil,
            parse: nil,
            link_names: nil,
            unfurl_links: nil,
            unfurl_media: nil,
            mrkdwn: nil,
            as_user: nil,
            username: nil,
            icon_emoji: nil,
            icon_url: nil)

          api.call_api("chat.postMessage",
            channel: api.channel_for(target),
            text: text,
            attachments: attachments,
            parse: parse,
            link_names: link_names,
            unfurl_links: unfurl_links,
            unfurl_media: unfurl_media,
            mrkdwn: mrkdwn,
            as_user: as_user,
            username: username,
            icon_emoji: icon_emoji,
            icon_url: icon_url)
        end

        #
        # Send a `/me` message to a Slack channel.
        #
        # @param target [Lita::Source, Lita::Room, Lita::User, String] A Lita
        #   source, room or user object, or a Slack channel ID, indicating where
        #   the message should be sent.
        # @param text [String] The message to /me send.
        # @return [Hash] The Slack sent message response, as seen in
        #   https://api.slack.com/methods/chat.meMessage#response . In
        #   particular, `response["ts"]` can be used as the `ts` argument to
        #   update_message and delete_message.
        def me_message(target, text)
          api.call_api("chat.meMessage",
            channel: api.channel_for(target),
            text: text)
        end

        #
        # Update an existing Slack message.
        #
        # Links on updated messages are not unfurled. Attachments are replaced
        # only if `attachments` are passed (otherwise they are left alone).
        #
        # You can get the `ts` of a message at creation time by taking the result
        # of `me_message` or `post_message`:
        #
        # @param target [Lita::Source, Lita::Room, Lita::User, String] A Lita
        #   source, room or user object, or a Slack channel ID, indicating where
        #   the message should be sent.
        # @param ts [String] The timestamp of the message (uniquely identifying
        #   it within the channel).
        # @param text [String] The text of the message. Either text or attachments
        #   is required.
        # @param attachments [Array<Hash, Attachment>] A list of attachments to
        #   the message. If `attachments` is not passed, the text is left alone;
        #   otherwise, it is entirely replaced. Each attachment must be either
        #   an attachment object or a Hash of the form specified in
        #   https://api.slack.com/docs/attachments#attachment_structure.
        #
        #   `pretext`, `title`, `text`, field `value` and `footer` are affected
        #   by `parse` and `link_names`.
        #
        #   Markdown is not enabled in any field by default. See the `mrkdwn_in`
        #   option to control markdown formatting in pretext, text
        #   and fields. Slack links like `<https://google.com|Google>` are
        #   *always* enabled in pretext, title, text, field values and footer,
        #   and never enabled in author_name and field titles.
        # @option attachments [String] :fallback Required plain-text summary of
        #   the attachment.
        # @option attachments [:good, :warning, :danger, String] :color The
        #   color of the left border of the attachment. good=green,
        #   warning=yellow, danger=red. Pass `"#<hex>"` for an arbitrary color
        #   (e.g. `"#439FE0"`).
        # @option mrkdwn_in [Array<String>] :mrkdwn_in The list of elements with
        #   markdown in them. Passing `["pretext"]` will enable markdown in
        #   `pretext` but not in `text`. Possible values include `"pretext"`,
        #   `"text"` and `"fields"` (which will affect only field values, not
        #   field titles). This does not affect Slack API links like
        #   `<https://google.com|Google>`. By default, markdown is not enabled
        #   anywhere.
        # @option attachments [String] :pretext The text to show before the
        #   attachment (will not be inside the color bar).
        # @option attachments [String] :author_name The author's full name to
        #   show at the top of the message, inside the color border.
        # @option attachments [String] :author_link A valid URL that will
        #   hyperlink the `author_name` text.
        # @option attachments [String] :author_icon A valid URL that displays a
        #   small 16x16px image to the left of the `author_name` text.
        # @option attachments [String] :title A title to display in larger,
        #   bold text at the top of the attachment, inside the color border).
        # @option attachments [String] :title_link A URL for the `title` to
        #   link to.
        # @option attachments [String] :text The text of the attachment.
        # @option attachments [Array<Hash>] :fields A list of fields to display,
        #  each of which is a Hash with `:title` and `:value` fields to display
        #  the name and value of the field, and an optional `:short` to indicate
        #  that the `value` is short enough to display side-by-side with other
        #  values. e.g. `[ { "title": "ID", value: "100", short: true }]`
        # @option attachments [String] :image_url A valid URL to a GIF, JPEG,
        #  PNG or BMP image that will be shown inside the attachment. Images
        #  larger than 400x500px will be resized down, maintaining aspect ratio.
        # @option attachments [String] :thumb_url A valid URL to a GIF, JPEG,
        #  PNG or BMP image that will be shown to the right of the attachment
        #  as a thumbnail. Images larger than 75x75px will be resized down,
        #  maintaining aspect ratio. Images must be smaller than 500KB.
        # @option attachments [String] :footer Brief context for the attachment
        #  that will be displayed below it, inside the color bar. Maximum
        #  300 characters.
        # @option attachments [String] :footer_icon A valid URL to a small icon
        #  to display next to the `footer`. Icons will be resized to 16x16px.
        # @option attachments [String] :ts Timestamp for the events described in the
        #  attachment, in UTC epoch time (e.g. `Time.now.utc.to_i`). Displayed
        #  to the right of the `footer`, inside the color bar.
        # @param parse ["none", "full"] Governs what formatting you can put in your
        #   messages and attachments.
        #
        #   Setting `parse` to `"none"` lets you pass links and directives with
        #   angle brackets `<https://google.com|Google>`, and automatically
        #   finds and linkifies URLs in the message (like `https://google.com`).
        #   See the [Slack formatting docs](https://api.slack.com/docs/formatting)
        #   for more information on the subject.
        #
        #   Setting `parse` to `"full"` disables angle bracket links and
        #   directives, instead showing the angle brackets to the user (so
        #   `<https://google.com|Google>` prints out as `<https://google.com|Google>`),
        #   and turns on `link_names`.
        #
        #   By default, angle brackets are ignored like in `full` but
        #   `link_names` remains off.
        # @param link_names [1] When set to `1`, tells Slack to find and linkify
        #   channel and usernames such as @user and #channel in messages and
        #   attachments. Slack has this off by default, but if `parse` is
        #   `"full"`, it's turned on.
        #
        # @return [Hash] The sent message response, as seen in
        #   https://api.slack.com/methods/chat.update#response.
        #
        # @example Creating and then updating a message
        #
        # ```
        # message = robot.chat_service.post_message(my_room, text: "Starting operation ...")
        # robot.chat_service.update_message(message["channel"], message["ts"], text: "Updated!")
        # ==> {"ok"=>true,
        #  "channel"=>"C134JG51Q",
        #  "ts"=>"1465849942.000079",
        #  "text"=>"Updated!",
        #  "message"=>
        #   {"text"=>"Updated!",
        #    "username"=>"bot",
        #    "bot_id"=>"B134DKK08",
        #    "mrkdwn"=>true,
        #    "type"=>"message",
        #    "subtype"=>"bot_message"}}
        # ```
        #
        def update_message(target, ts,
          text: nil,
          attachments: nil,
          parse: nil,
          link_names: nil
          )

          api.call_api("chat.update",
            channel: api.channel_for(target),
            ts: ts,
            text: text,
            attachments: attachments,
            parse: parse,
            link_names: link_names)
        end

        #
        # Delete an existing Slack message.
        #
        # @param target [Lita::Room, Lita::User] A room or user object
        #   indicating where the message should be sent.
        # @param ts [String] The timestamp of the message (uniquely identifying
        #   it within the channel).
        #
        # @return [Hash] The Slack deleted message response, as seen in
        #   https://api.slack.com/methods/chat.delete#response .
        #
        def delete_message(target, ts)
          api.call_api("chat.delete", channel: api.channel_for(target), ts: ts)
        end

        #
        # Send attachments to Slack.
        #
        # @param target [Lita::Source, Lita::Room, Lita::User] A room or user
        #        object indicating where the attachment should be sent.
        # @param attachments [Attachment, Hash, Array<Attachment>, Hash<String>] An {Attachment} or array of
        #   {Attachment}s to send.
        #
        # @return [void]
        #
        def send_attachments(target, attachments)
          post_message(target, attachments: Array(attachments))
        end
        alias_method :send_attachment, :send_attachments
      end
    end
  end
end
