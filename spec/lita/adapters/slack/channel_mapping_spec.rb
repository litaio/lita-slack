require "spec_helper"

describe Lita::Adapters::Slack::ChannelMapping do
  subject { described_class.new(channels) }

  let(:api) { instance_double('Lita::Adapters::Slack::API') }
  let(:channel) { Lita::Adapters::Slack::SlackChannel.new('C1234567890', 'Room 10', 1360782804, 'U023BECGF', raw_data) }
  let(:raw_data) { Hash.new }


  describe "#channel_for" do
    context "when a mapping is already stored" do
      let(:channels) { [channel] }

      it "returns the Channel name for the given channel ID" do
        expect(subject.channel_for('C1234567890')).to eq('Room 10')
      end
    end

=begin
    context "when a channel is not yet created" do
      before do
        allow(api).to receive(:channel_create).with('Room 10').and_return(channel).once
      end


      let(:channels) { [] }

      it "fetch the channel name from the API using the channel id" do
        expect(subject.channel_for('C1234567890')).to eq('Room 10')
      end
    end
=end
  end
end
