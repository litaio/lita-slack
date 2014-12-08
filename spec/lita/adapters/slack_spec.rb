require "spec_helper"

describe Lita::Adapters::Slack, lita: true do
  subject { described_class.new(robot) }

  let(:robot) { Lita::Robot.new(registry) }
  let(:token) { 'abcd-1234567890-hWYd21AmMH2UHAkx29vb5c1Y' }

  before do
    registry.register_adapter(:slack, described_class)
    registry.config.adapters.slack.token = token
  end

  it "registers with Lita" do
    expect(Lita.adapters[:slack]).to eql(described_class)
  end

  describe "#run" do
  end
end
