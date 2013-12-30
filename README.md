# lita-slack

**lita-slack** is an adapter for [Lita](https://github.com/jimmycuadra/lita) that allows you to use the robot with [Slack](https://slack.com/). As **lita-slack** is one way, robot messages to Slack, it depends on [lita-slack-handler](https://github.com/kenjij/lita-slack-handler) gem to receive messages from Slack.

## Installation

Add **lita-slack** and **lita-slack-handler** to your Lita instance's Gemfile:

``` ruby
gem "lita-slack"
gem "lita-slack-handler"
```

## Configuration

**First, you need to make sure your Slack team has [Incoming WebHooks](https://my.slack.com/services/new/incoming-webhook) integration setup. For configuration regarding lita-slack-handler, see its [README](https://github.com/kenjij/lita-slack-handler).**

Then, define the following attributes:

### Required attributes

* `incoming_token` (String) – Slack integration token.
* `team_domain` (String) – Slack team domain; subdomain of slack.com.

### Optional attributes

* `incoming_url` (String) – Default: https://<team_domain>.slack.com/services/hooks/incoming-webhook
* `username` (String) – Display name of the robot; default: whatever is set in Slack integration
* `add_mention` (Bool) – Always prefix message with mention of the user which it's directed to; this triggers a notification.

### Example lita_config.rb

``` ruby
Lita.configure do |config|
  config.robot.name = "Lita"
  config.robot.mention_name = "@lita"
  # Select the Slack adapter
  config.robot.adapter = :slack
  # lita-slack adapter config
  config.adapter.incoming_token = "aN1NvAlIdDuMmYt0k3n"
  config.adapter.team_domain = "example"
  config.adapter.username = "lita"
  # Some more handlers and other config
  # .....
end
```

## License

[MIT](http://opensource.org/licenses/MIT)
