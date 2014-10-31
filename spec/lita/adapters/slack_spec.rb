require "spec_helper"

describe Lita::Adapters::Slack, lita: true do
  before do
    registry.register_adapter(:slack, described_class)

    registry.configure do |config|
      config.adapters.slack.incoming_token = 'aN1NvAlIdDuMmYt0k3n'
      config.adapters.slack.team_domain = 'example'
      config.adapters.slack.username = 'lita'
      config.adapters.slack.add_mention = true
    end
  end

  subject { described_class.new(robot) }
  let(:robot) { Lita::Robot.new(registry) }

  it "registers with Lita" do
    expect(Lita.adapters[:slack]).to eql(described_class)
  end

  describe "#send_messages" do
    it "sends JSON payload via HTTP POST to Slack channel" do
      target = double("Lita::Source", room: "CR00M1D")
      payload = {
        'channel' => target.room,
        'username' => registry.config.adapters.slack.username,
        'text' => 'Hello!'
      }
      expect(subject).to receive(:http_post).with(payload)
      subject.send_messages(target, ["Hello!"])
    end

    it "sends message with mention if user info is provided" do
      user = double("Lita::User", id: "UM3NT10N")
      target = double("Lita::Source", room: "CR00M1D", user: user)
      text = "<@#{user.id}> Hello!"
      payload = {
        'channel' => target.room,
        'username' => registry.config.adapters.slack.username,
        'text' => text
      }
      expect(subject).to receive(:http_post).with(payload)
      subject.send_messages(target, ["Hello!"])
    end

    it "proceeds but logs WARN when directed to an user without channel(room) info" do
      user = double("Lita::User", id: "UM3NT10N")
      target = double("Lita::Source", user: user)
      text = "<@#{user.id}> Hello!"
      payload = {
        'channel' => nil,
        'username' => registry.config.adapters.slack.username,
        'text' => text
      }
      expect(subject).to receive(:http_post).with(payload)
      expect(Lita.logger).to receive(:warn).with(/without channel/)
      subject.send_messages(target, ["Hello!"])
    end
  end
end
