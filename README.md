# lita-slack

[![Gem Version](https://badge.fury.io/rb/lita-slack.png)](http://badge.fury.io/rb/lita-slack)
[![Build Status](https://travis-ci.org/kenjij/lita-slack.png?branch=master)](https://travis-ci.org/kenjij/lita-slack)

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

**Note**: When using lita-slack, the adapter will overwrite the bot's name and mention name with the values set on the server, so `config.robot.name` and `config.robot.mention_name` will have no effect.

### config.robot.admins

Each Slack user has a unique ID that never changes even if their real name or username changes. To populate the `config.robot.admins` attribute, you'll need to use these IDs for each user you want to mark as an administrator. If you're using Lita version 4.1 or greater, you can get a user's ID by sending Lita the command `users find NICKNAME_OF_USER`.

### Example

``` ruby
Lita.configure do |config|
  config.robot.adapter = :slack
  config.robot.admins = ["U012A3BCD"]
  config.adapters.slack.token = "abcd-1234567890-hWYd21AmMH2UHAkx29vb5c1Y"
  config.adapters.slack.parse = "full" # See https://api.slack.com/docs/formatting#parsing_modes
end
```

## Joining rooms

Lita will join your default channel after initial setup. To have it join additional channels or private groups, simply invite it to them via your Slack client as you would any normal user.

## Events

* `:connected` - When the robot has connected to Slack. No payload.
* `:disconnected` - When the robot has disconnected from Slack. No payload.
* `:slack_user_created` - When the robot creates/updates a user's info - name, mention name, etc., as directed by Slack. The payload has a single object, a `Lita::Slack::Adapters::SlackUser` object, under the `:slack_user` key.
* `:slack_channel_created` - When the robot creates/updates a channel's or group's info, as directed by Slack. The payload has a single object, a `Lita::Slack::Adapters::SlackChannel` object, under the `:slack_channel` key.

## Chat service API

lita-slack supports Lita 4.6's chat service API for Slack-specific functionality. You can access this API object by calling the `Lita::Robot#chat_service`. See the API docs for `Lita::Adapters::Slack::ChatService` for details about the provided methods.

## API documentation

The API documentation, useful for plugin authors, can be found for the latest gem release on [RubyDoc.info](http://www.rubydoc.info/gems/lita-slack)

## License

[MIT](http://opensource.org/licenses/MIT)
