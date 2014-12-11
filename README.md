# lita-slack

**lita-slack** is an adapter for [Lita](https://www.lita.io/) that allows you to use the robot with [Slack](https://slack.com/). The current adapter is not compatible with pre-1.0.0 versions, as it now uses Slack's [Real Time Messaging API](https://api.slack.com/rtm).

## Installation

Add **lita-slack** to your Lita instance's Gemfile:

``` ruby
gem "lita-slack"
```

## Configuration

### Required attributes

* `token` (String) – The bot's Slack API token. Create a bot and get its token at https://my.slack.com/services/new/lita.

**Note**: When using lita-slack, the adapter will overwrite the bot's name and mention name with the values set on the server, so `config.robot.name` and `config.robot.mention_name` will have no effect.

### Example

``` ruby
Lita.configure do |config|
  config.robot.adapter = :slack
  config.adapters.slack.token = "abcd-1234567890-hWYd21AmMH2UHAkx29vb5c1Y"
end
```

## Events

* `:connected` - When the robot has connected to Slack. No payload.
* `:disconnected` - When the robot has disconnected from Slack. No payload.

## License

[MIT](http://opensource.org/licenses/MIT)
