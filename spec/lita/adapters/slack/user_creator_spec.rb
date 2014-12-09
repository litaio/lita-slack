require "spec_helper"

describe Lita::Adapters::Slack::UserCreator do
  describe ".create_users" do
    before { allow(Lita::User).to receive(:create) }

    it "creates Lita users for each user in the provided data" do
      expect(Lita::User).to receive(:create).with(
        'U023BECGF',
        name: 'Bobby Tables',
        mention_name: 'bobby'
      )

      described_class.create_users([{
        'id' => 'U023BECGF',
        'name' => 'bobby',
        'profile' => {
          'real_name' => 'Bobby Tables'
        }
      }])
    end

    it "uses the mention name if no real name is available" do
      expect(Lita::User).to receive(:create).with(
        'U023BECGF',
        name: 'bobby',
        mention_name: 'bobby'
      )

      described_class.create_users([{
        'id' => 'U023BECGF',
        'name' => 'bobby',
      }])
    end
  end
end
