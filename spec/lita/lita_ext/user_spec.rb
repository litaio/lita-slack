# Specs for monkey-patches to Lita::User
require "spec_helper"

describe Lita::User, lita: true do
  describe ".find_by_email" do
    it "returns nil if no user matches the provided e-mail address" do
      expect(described_class.find_by_email("carlthepug")).to be_nil
    end

    it "returns a user that matches the provided email" do
      described_class.create(1, email: "carl@pugs.com")
      user = described_class.find_by_email("carl@pugs.com")
      expect(user.id).to eq("1")
    end
  end

  describe "#save" do
    subject { described_class.new(1, name: "Carl", mention_name: "carlthepug", email: "carl@pugs.com") }

    it "saves an e-mail address to ID mapping for the user in Redis" do
      subject.save
      expect(described_class.redis.get("email:carl@pugs.com")).to eq("1")
    end
  end
end
