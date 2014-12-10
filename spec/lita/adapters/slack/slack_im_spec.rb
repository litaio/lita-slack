require "spec_helper"

describe Lita::Adapters::Slack::SlackIM do
  let(:im_data_1) do
    {
      "id" => "D024BFF1M",
      "is_im" => true,
      "user" => "U024BE7LH",
      "created" => 1360782804,
    }
  end
  let(:im_data_2) do
    {
      "id" => "D012ABC3E",
      "is_im" => true,
      "user" => "U098ZYX7W",
      "created" => 1360782904,
    }
  end
  let(:ims_data) { [im_data_1, im_data_2] }

  describe ".from_data_array" do
    subject { described_class.from_data_array(ims_data) }

    it "returns an object for each hash of IM data" do
      expect(subject.size).to eq(2)
    end

    it "creates SlackIM objects" do
      expect(subject[0].id).to eq('D024BFF1M')
      expect(subject[0].user_id).to eq('U024BE7LH')
      expect(subject[1].id).to eq('D012ABC3E')
      expect(subject[1].user_id).to eq('U098ZYX7W')
    end
  end
end
