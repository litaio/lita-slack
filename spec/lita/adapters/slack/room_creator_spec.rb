require "spec_helper"

describe Lita::Adapters::Slack::RoomCreator, lita: true do
  describe ".create_rooms" do
    before { allow(robot).to receive(:trigger) }

    let(:robot) { instance_double('Lita::Robot') }

    let(:group) do
      Lita::Adapters::Slack::SlackChannel.from_data('id' => 'G1234567890', 'name' => 'mygroup')
    end

    let(:room) do
      Lita::Adapters::Slack::SlackChannel.from_data('id' => 'C1234567890', 'name' => 'mychannel')
    end

    it "creates a Room for each Slack channel" do
      described_class.create_rooms([room] + [group], robot)

      expect(Lita::Room.find_by_name("mychannel").id).to eq("C1234567890")
      expect(Lita::Room.find_by_name("mygroup").id).to eq("G1234567890")
    end

    it "triggers the slack_channel_created event" do
      expect(robot).to receive(:trigger).with(:slack_channel_created, slack_channel: room)
      expect(robot).to receive(:trigger).with(:slack_channel_created, slack_channel: group)

      described_class.create_rooms([room] + [group], robot)
    end
  end
end
