require "spec_helper"

describe Lita::Adapters::Slack::IMMapping do
  subject { described_class.new(api, ims_data) }

  let(:api) { instance_double('Lita::Adapters::Slack::API') }
  let(:ims_data) { [{'user' => 'U023BECGF', 'id' => 'D024BFF1M'}] }
  let(:im_open_response) { Lita::Adapters::Slack::SlackIM.new('D1234567890', 'U023BECGF') }

  describe "#im_for" do
    context "when a mapping is already stored" do
      it "returns the IM ID for the given user ID" do
        expect(subject.im_for('U023BECGF')).to eq('D024BFF1M')
      end
    end

    context "when a mapping is not yet stored" do
      before do
        allow(api).to receive(:im_open).with('U934DJWLK').and_return(im_open_response).once
      end

      it "fetches the IM ID from the API and returns it" do
        expect(subject.im_for('U934DJWLK')).to eq('D1234567890')
      end

      it "doesn't hit the API on subsequent look ups of the same user ID" do
        expect(subject.im_for('U934DJWLK')).to eq(subject.im_for('U934DJWLK'))
      end
    end
  end
end
