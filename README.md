# lita-slack

[![Gem Version](https://badge.fury.io/rb/lita-slack.png)](http://badge.fury.io/rb/lita-slack)
[![Build Status](https://travis-ci.org/litaio/lita-slack.png?branch=master)](https://travis-ci.org/litaio/lita-slack)

**lita-slack** is an adapter for [Lita](https://www.lita.io/) that allows you to use the robot with [Slack](https://slack.com/). The current adapter is not compatible with pre-1.0.0 versions, as it now uses Slack's [Real Time Messaging API](https://api.slack.com/rtm).

## Installation

Add **lita-slack** to your Lita instance's Gemfile:

``` ruby
gem "lita-slack"
```

## Configuration

### Required attributes

* `token` (String) – The bot's Slack API token. Create a bot and get its token at https://my.slack.com/services/new/lita.

### Optional attributes

* `proxy` (String) – Specify a HTTP proxy URL. (e.g. "http://squid.example.com:3128")
* `default_message_arguments` - Default message arguments for all messages sent by Lita to Slack. Defaults to `{ as_user: true }`. See [below](#message_arguments) for more explanation. Overrides any values in `link_names`, `parse`, `unfurl_links` or `unfurl_media`. NOTE: if you override this and want `as_user: true`, you will need to set it in your own `default_message_arguments` value explicitly.
* `link_names` (Boolean) – Set to `true` to turn all Slack usernames in messages sent by Lita into links.
* `parse` (String) – Specify the parsing mode. See https://api.slack.com/docs/formatting#parsing_modes.
* `unfurl_links` (Boolean) – Set to `true` to automatically add previews for all links in messages sent by Lita.
* `unfurl_media` (Boolean) – Set to `false` to prevent automatic previews for media files in messages sent by Lita.

**Note**: When using lita-slack, the adapter will overwrite the bot's name and mention name with the values set on the server, so `config.robot.name` and `config.robot.mention_name` will have no effect.

### config.robot.admins

Each Slack user has a unique ID that never changes even if their real name or username changes. To populate the `config.robot.admins` attribute, you'll need to use these IDs for each user you want to mark as an administrator. If you're using Lita version 4.1 or greater, you can get a user's ID by sending Lita the command `users find NICKNAME_OF_USER`.

### Example

``` ruby
Lita.configure do |config|
  config.robot.adapter = :slack
  config.robot.admins = ["U012A3BCD"]

  config.adapters.slack.token = "abcd-1234567890-hWYd21AmMH2UHAkx29vb5c1Y"

  config.adapters.slack.link_names = true
  config.adapters.slack.parse = "full"
  config.adapters.slack.unfurl_links = false
  config.adapters.slack.unfurl_media = false
end
```

## Joining rooms

Lita will join your default channel after initial setup. To have it join additional channels or private groups, simply invite it to them via your Slack client as you would any normal user.

## Events

* `:connected` - When the robot has connected to Slack. No payload.
* `:disconnected` - When the robot has disconnected from Slack. No payload.
* `:slack_channel_created` - When the robot creates/updates a channel's or group's info, as directed by Slack. The payload has a single object, a `Lita::Slack::Adapters::SlackChannel` object, under the `:slack_channel` key.
* `:slack_reaction_added` - When a reaction has been added to a previous message. The payload includes `:user` (a `Lita::User` for the sender of the message in question), `:name` (the string name of the reaction added), `:item` (a hash of raw data from Slack about the message), and `:event_ts` (a string timestamp used to identify the message).
* `:slack_reaction_removed` - When a reaction has been removed from a previous message. The payload is the same as the `:slack_reaction_added` message.
* `:slack_user_created` - When the robot creates/updates a user's info - name, mention name, etc., as directed by Slack. The payload has a single object, a `Lita::Slack::Adapters::SlackUser` object, under the `:slack_user` key.

## Chat service API

lita-slack supports Lita 4.6's chat service API for Slack-specific functionality. You can access this API object by calling the `Lita::Robot#chat_service`. See the API docs for `Lita::Adapters::Slack::ChatService` for details about the provided methods.

## Messages and Formatting

To promote cross-chat-service bots, messages sent to Slack via the Lita API do
not allow Slack's custom formatting (for example, links like `<https://google.com|Google>`) that will not work in other services.

The message arguments passed to the Slack API determine how your message and
attachment text is treated. By default, only `as_user: true` is sent to the API,
which means link formatting like `<https://google.com|Google>` is disregarded, and
media URLs like youtube and imgur will be auto-unfurled and have the videos/images
shown directly in the channel, but other URLs like Github and Slack will not be
unfurled.

In order to take full advantage of Slack, you can call
`robot.chat_service.send_message(room_or_user[, "message"], attachments: [...], **message_arguments)`. Message arguments are the same as the [chat.postMessage API](https://api.slack.com/methods/chat.postMessage#arguments), and include:

| Argument      | Description                                                  |
|---------------|--------------------------------------------------------------|
| `as_user`     | Determines whether the bot posts as an authenticated user. If set to `true`, `username`, `icon_emoji` and `icon_url` on the message are ignored and the actual bot user's username, icon_emoji and icon_url are used. Posting as a bot can be useful if you want to change the bot's icon on a per-message basis. If this is not set, Slack will guess a value for you. (If you did not set `default_message_arguments`, `as_user` will default to `true`.)
| `username`     | The display name for the user (not the `@nickname`, the full name).
| `icon_emoji`   | An emoji for the Bot's post (e.g. `:lol:`).
| `icon_url`     | The URL to an image for the Bot's icon.
| `parse`        | Governs what formatting you can put in your messages. `none` lets you fully format your message [the Slack way](https://api.slack.com/docs/formatting) (so `<https://google.com|Google>` prints out as `Google`). `full` does not honor Slack formatting, escaping characters in the message exactly as you sent them (so `<https://google.com|Google>` prints out as `<https://google.com|Google>`), and turns `unfurl_links` on.
| `link_names`   | When set to 1, tells Slack to find and linkify channel and usernames such as @user and #channel. Slack has this off by default.
| `unfurl_media` | When set to `true`, Slack will find URLs in your message that point to images, video, sound, etc. and [generate attachments for them](https://api.slack.com/docs/unfurling) automatically. Slack defaults this to `true`.
| `unfurl_links` | When set to `true`, Slack will find URLs in your message that point to non-media stuff (like Google or Github) and generate an attachment automatically for them. Slack defaults this to `false`.

Because message arguments are sent without processing to Slack, when the
Slack API adds new arguments and argument values in the future, they will be
automatically supported. Any options you do not specify will not be passed to
Slack, and Slack will use its own defaults for them.

If you want all messages to have the same options by default, you can set any of the above properties by setting them in `config.default_message_arguments`. For example, this will cause channel names to be linkified in all messages:

```ruby
config.adapters.slack.default_message_arguments = { as_user: true, link_names: 1 }
```

### Attachments

The `post_slack_message` method accepts attachments using the [Slack attachment structure](https://api.slack.com/docs/attachments):

```
robot.chat_service.post_slack_message(room_or_user, attachments: [
    {
      pretext: "The build is broke!",
      text: "your build!\nit\nis\nbroken.\ncould it be worse?\n... probably",
      color: "danger",
      thumb_url: "https://thumbnails.com/brokenbuild.jpg"
    }
])
```

Like `message_arguments`, attachments are passed verbatim to the Slack API.

## API documentation

The API documentation, useful for plugin authors, can be found for the latest gem release on [RubyDoc.info](http://www.rubydoc.info/gems/lita-slack)

## License

[MIT](http://opensource.org/licenses/MIT)
