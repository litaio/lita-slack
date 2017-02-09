require "spec_helper"

describe Lita::Adapters::Slack::SlackUser do
  let(:user_data_1) do
    {
      "id" => "U023BECGF",
      "name" => "bobby",
      "real_name" => "Bobby Tables",
      "profile" => {
        "email" => "btables@example.com"
      }
    }
  end
  let(:user_data_2) do
    {
      "id" => "U024BE7LH",
      "name" => "carl",
    }
  end
  let(:users_data) { [user_data_1, user_data_2] }

  describe ".from_data_array" do
    subject { described_class.from_data_array(users_data) }

    it "returns an object for each hash of user data" do
      expect(subject.size).to eq(2)
    end

    it "creates SlackUser objects" do
      expect(subject[0].id).to eq('U023BECGF')
      expect(subject[0].name).to eq('bobby')
      expect(subject[0].real_name).to eq('Bobby Tables')
      expect(subject[0].profile['email']).to eq('btables@example.com')
      expect(subject[1].id).to eq('U024BE7LH')
      expect(subject[1].name).to eq('carl')
      expect(subject[1].real_name).to eq('')
      expect(subject[1].profile['email']).to eq('')
    end

    it "raw_data matches the metadata" do
      expect(subject[0].metadata['name']).to eq(subject[0].raw_data['name'])
    end
  end
end
