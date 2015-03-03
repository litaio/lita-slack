require 'spec_helper'

describe Lita::Adapters::Slack::EventLoop, lita: true do
  describe '.run' do
    it 'runs the provided block in Eventmachine' do
      allow(EM).to receive(:run).and_yield
      ran = false

      described_class.run { ran = true }

      expect(ran).to be_truthy
    end
  end

  describe '.safe_stop' do
    it 'stops Eventmachine when the reactor is running' do
      described_class.run do
        expect(EM.reactor_running?).to be_truthy

        described_class.safe_stop
      end

      expect(EM.reactor_running?).to be_falsy
    end

    it 'does nothing when the reactor is not running' do
      expect(EM).not_to receive(:stop)

      described_class.safe_stop
    end
  end
end
