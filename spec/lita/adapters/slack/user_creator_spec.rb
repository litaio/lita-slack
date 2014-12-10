require "spec_helper"

describe Lita::Adapters::Slack::UserCreator do
  before { allow(Lita::User).to receive(:create) }

  let(:robot) { instance_double('Lita::Robot') }

  describe ".create_users" do
    let(:real_name) { 'Bobby Tables' }
    let(:bobby) { Lita::Adapters::Slack::SlackUser.new('U023BECGF', 'bobby', real_name) }
    let(:robot_id) { 'U12345678' }

    it "creates Lita users for each user in the provided data" do
      expect(Lita::User).to receive(:create).with(
        'U023BECGF',
        name: 'Bobby Tables',
        mention_name: 'bobby'
      )

      described_class.create_users([bobby], robot, robot_id)
    end

    context "when the Slack user has no real name set" do
      let(:real_name) { "" }

      it "uses the mention name if no real name is available" do
        expect(Lita::User).to receive(:create).with(
          'U023BECGF',
          name: 'bobby',
          mention_name: 'bobby'
        )

        described_class.create_users([bobby], robot, robot_id)
      end
    end
  end

  describe ".create_user" do
    let(:robot_id) { 'U12345678' }
    let(:slack_user) { Lita::Adapters::Slack::SlackUser.new(robot_id, 'litabot', 'Lita Bot') }

    it "updates the robot's name and mention name if it applicable" do
      expect(robot).to receive(:name=).with('Lita Bot')
      expect(robot).to receive(:mention_name=).with('litabot')

      described_class.create_user(slack_user, robot, robot_id)
    end
  end
end
