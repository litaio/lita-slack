require "spec_helper"

describe Lita::Adapters::Slack::SlackChannel do
  let(:channel_data_1) do
    {
        "id" => "C2147483705",
        "name" => "Room 1",
        "created" => 1360782804,
        "creator" => 'U023BECGF'
    }
  end
  let(:channel_data_2) do
    {
        "id" => "C2147483706",
        "name" => "Room 2",
        "created" => 1360782805,
        "creator" => 'U023BECGF'
    }
  end
  let(:channels_data) { [channel_data_1, channel_data_2] }

  describe ".from_data_array" do
    subject { described_class.from_data_array(channels_data) }

    it "returns an object for each hash of Channel data" do
      expect(subject.size).to eq(2)
    end

    it "creates SlackIM objects" do
      expect(subject[0].id).to eq('C2147483705')
      expect(subject[0].name).to eq('Room 1')
      expect(subject[0].creator).to eq('U023BECGF')
      expect(subject[0].created).to eq(1360782804)
      expect(subject[1].id).to eq('C2147483706')
      expect(subject[1].name).to eq('Room 2')
      expect(subject[1].creator).to eq('U023BECGF')
      expect(subject[1].created).to eq(1360782805)
    end
  end
end
