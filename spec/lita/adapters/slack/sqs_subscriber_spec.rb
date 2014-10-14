require 'spec_helper'
require 'lita/adapters/slack/sqs_subscriber'

describe Lita::Adapters::Slack::SqsSubscriber do
  let(:queue) { instance_double(AWS::SQS::Queue) }
  let(:queues) { instance_double(AWS::SQS::QueueCollection) }
  let(:sqs_client) { instance_double(AWS::SQS, queues: queues) }
  let(:sqs_message) { instance_double(AWS::SQS::ReceivedMessage) }
  let(:robot) { instance_double(Lita::Robot) }
  let(:config) { Lita.config.adapter }
  before do
    Lita.configure do |config|
      config.adapter.sqs_aws_access_key_id = 'keyid'
      config.adapter.sqs_aws_secret_access_key = 'secretkey'
      config.adapter.sqs_queue_name = 'queuename'
    end
  end

  describe '.listen' do
    before do
      allow(AWS::SQS).to receive(:new).
        with(access_key_id: 'keyid', secret_access_key: 'secretkey').
        and_return(sqs_client)
      allow(queues).to receive(:named).with('queuename').and_return(queue)
      allow(queue).to receive(:poll).and_yield(sqs_message)
      allow(Thread).to receive(:new).and_yield
    end

    it 'fetches SQS events and processes them' do
      expect(Lita::Adapters::SqsSender).to receive(:deliver).
        with(robot, sqs_message, config)
      expect(sqs_message).to receive(:delete)
      described_class.listen(robot)
    end
  end
end
