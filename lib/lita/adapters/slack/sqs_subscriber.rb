require 'aws-sdk'
require 'lita/adapters/slack/sqs_sender'

module Lita
  module Adapters
    class Slack < Adapter
      class SqsSubscriber
        def self.listen(robot)
          new.listen(robot)
        end

        def listen(robot)
          Thread.new do
            queue.poll do |message|
              SqsSender.deliver(robot, message, config)
              message.delete
            end
          end
        end

        private

        def robot_id
          config.robot_id
        end

        def queue
          sqs.queues.named(config.sqs_queue_name)
        end

        def sqs
          AWS::SQS.new(
            access_key_id: config.sqs_aws_access_key_id,
            secret_access_key: config.sqs_aws_secret_access_key
          )
        end

        def config
          Lita.config.adapter
        end
      end
    end
  end
end
