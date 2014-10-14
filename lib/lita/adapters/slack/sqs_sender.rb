module Lita
  module Adapters
    class SqsSender
      def self.deliver(robot, message, config)
        new(robot, config).deliver(message)
      end

      def initialize(robot, config)
        @robot = robot
        @config = config
      end

      def deliver(message)
        parse(message)
        @robot.receive(lita_message) if channel_whitelisted? && not_self?
      end

      private

      def parse(message)
        @payload = JSON.parse(message.body)
      end

      def not_self?
        robot_id != user_id
      end

      def channel_whitelisted?
        channel_ids.nil? || channel_ids.include?(channel_id)
      end

      def robot_id
        @config.robot_id
      end

      def channel_ids
        @config.channel_ids
      end

      def user_id
        @payload['user_id']
      end

      def user_name
        @payload['user_name']
      end

      def channel_id
        @payload['channel_id']
      end

      def text
        @payload['text']
      end

      def user
        Lita::User.create(user_id, user_name: user_name)
      end

      def source
        Lita::Source.new(user: user, room: channel_id)
      end

      def lita_message
        Lita::Message.new(@robot, text, source)
      end
    end
  end
end
