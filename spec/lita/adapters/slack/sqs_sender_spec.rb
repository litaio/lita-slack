require 'spec_helper'
require 'lita/adapters/slack/sqs_sender'

describe Lita::Adapters::SqsSender do
  let(:robot) do
    double(
      Lita::Robot,
      mention_name: 'robot',
      alias: 'robot'
    )
  end
  let(:robot_adapter) { double(:adapter, config_attributes) }
  let(:user_id) { 'U2147483697' }
  let(:user_name) { 'Steve' }
  let(:text) { 'long text' }
  let(:channel_id) { 'AHH3246JD' }
  let(:user) { instance_double(Lita::User) }
  let(:source) { instance_double(Lita::Source) }
  let(:sqs_message) { instance_double(AWS::SQS::ReceivedMessage, body: message_body) }
  let(:message) { instance_double(Lita::Message) }

  describe '.deliver' do
    before do
      allow(Lita::User).to receive(:create).
        with(user_id, user_name: user_name).
        and_return(user)
      allow(Lita::Source).to receive(:new).
        with(user: user, room: channel_id).
        and_return(source)
      allow(Lita::Message).to receive(:new).
        with(robot, text, source).
        and_return(message)

    end

    context 'when origin channel is whitelisted' do
      context 'when a message does not come from itself' do
        let(:config_attributes) { { robot_id: 'UANOTHERONE', channel_ids: [channel_id] } }

        it 'delivers a new message to the robot' do
          expect(robot).to receive(:receive).with(message)
          described_class.deliver(robot, sqs_message, robot_adapter)
        end
      end

      context 'when a message come from itself' do
        let(:config_attributes) { { robot_id: user_id, channel_ids: [channel_id] } }

        it 'does not deliver a new message to the robot' do
          expect(robot).not_to receive(:receive).with(message)
          described_class.deliver(robot, sqs_message, robot_adapter)
        end
      end
    end
  end

  context 'when origin channel is not whitelisted' do
    let(:config_attributes) { { robot_id: 'UANOTHERONE', channel_ids: ['NOCHANNEL'] } }

    it 'does not receive a message' do
      expect(robot).not_to receive(:receive)
      described_class.deliver(robot, sqs_message, robot_adapter)
    end
  end

  context 'when channel_ids is not defined' do
    let(:config_attributes) { { robot_id: 'UANOTHERONE', channel_ids: nil } }

    it 'receives a message' do
      expect(robot).to receive(:receive)
      described_class.deliver(robot, sqs_message, robot_adapter)
    end
  end

  def message_body
    '{"token": "q3it7HawhPvos4eb7a0Fn508", "team_id": "T0001",' +
      %Q["channel_id": "#{channel_id}", "channel_name": "test",] +
      %Q["timestamp": "1355517523.000005", "user_id": "#{user_id}",] +
      %Q["user_name": "#{user_name}", "text": "#{text}" }]
  end
end
