require "spec_helper"

describe Lita::Adapters::Slack::UserCreator do
  before { allow(Lita::User).to receive(:create) }

  let(:robot) { instance_double('Lita::Robot') }

  describe ".create_users" do
    let(:bobby_data) do
      {
        'id' => 'U023BECGF',
        'name' => 'bobby',
        'profile' => {
          'real_name' => 'Bobby Tables'
        }
      }
    end
    let(:robot_id) { 'U12345678' }

    it "creates Lita users for each user in the provided data" do
      expect(Lita::User).to receive(:create).with(
        'U023BECGF',
        name: 'Bobby Tables',
        mention_name: 'bobby'
      )

      described_class.create_users([bobby_data], robot, robot_id)
    end

    it "uses the mention name if no real name is available" do
      expect(Lita::User).to receive(:create).with(
        'U023BECGF',
        name: 'bobby',
        mention_name: 'bobby'
      )

      bobby_data.delete('profile')
      described_class.create_users([bobby_data], robot, robot_id)
    end
  end

  describe ".create_user" do
    let(:robot_id) { 'U12345678' }
    let(:user_data) do
      {
        'id' => robot_id,
        'name' => 'litabot',
        'profile' => {
          'real_name' => 'Lita Bot'
        }
      }
    end

    it "updates the robot's name and mention name if it applicable" do
      expect(robot).to receive(:name=).with('Lita Bot')
      expect(robot).to receive(:mention_name=).with('litabot')

      described_class.create_user(user_data, robot, robot_id)
    end
  end
end
