require "spec_helper"

describe Lita::Adapters::Slack::SlackSource, lita: true do
  subject { described_class.new(room: room_source, extensions: extensions) }

  let(:room_source) { Lita::Source.new(room: 'C024BE91L') }

  describe "with timestamps" do
    let(:extensions) do
      { 
        :timestamp => "123456.789",
        :thread_ts => "98765.12" 
      }
    end

    it "can read timestamp" do
      expect(subject.timestamp).to eq("123456.789")
    end

    it "can read thread_ts" do
      expect(subject.thread_ts).to eq("98765.12")
    end
  end

  describe "without extensions" do
    let(:extensions) { { } }

    it "can read timestamp" do
      expect(subject.timestamp).to eq(nil)
    end

    it "can read thread_ts" do
      expect(subject.thread_ts).to eq(nil)
    end
  end
end
