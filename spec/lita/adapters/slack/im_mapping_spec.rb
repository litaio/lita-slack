require "spec_helper"

describe Lita::Adapters::Slack::IMMapping do
  subject { described_class.new(api, ims) }

  let(:api) { instance_double('Lita::Adapters::Slack::API') }
  let(:im) { Lita::Adapters::Slack::SlackIM.new('D1234567890', 'U023BECGF') }

  describe "#im_for" do
    context "when a mapping is already stored" do
      let(:ims) { [im] }

      it "returns the IM ID for the given user ID" do
        expect(subject.im_for('U023BECGF')).to eq('D1234567890')
      end
    end

    context "when a mapping is not yet stored" do
      before do
        allow(api).to receive(:im_open).with('U023BECGF').and_return(im).once
      end

      let(:ims) { [] }

      it "fetches the IM ID from the API and returns it" do
        expect(subject.im_for('U023BECGF')).to eq('D1234567890')
      end

      it "doesn't hit the API on subsequent look ups of the same user ID" do
        expect(subject.im_for('U023BECGF')).to eq(subject.im_for('U023BECGF'))
      end
    end
  end
end
