require "spec_helper"

describe Lita::Source do
  subject { described_class.new(room: 'R0000', thread: 'thread') }

  it 'records message source thread' do
    expect(subject.thread).to eq('thread')
  end

end
