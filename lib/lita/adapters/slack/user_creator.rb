module Lita
  module Adapters
    class Slack < Adapter
      # @api private
      class UserCreator
        class << self
          def create_user(slack_user, robot, robot_id)
            User.create(
              slack_user.id,
              metadata(slack_user)
            )

            update_robot(robot, slack_user) if slack_user.id == robot_id
            robot.trigger(:slack_user_created, slack_user: slack_user)
          end

          def create_users(slack_users, robot, robot_id)
            slack_users.each { |slack_user| create_user(slack_user, robot, robot_id) }
          end

          private

          def real_name(slack_user)
            slack_user.real_name.size > 0 ? slack_user.real_name : slack_user.name
          end

          def update_robot(robot, slack_user)
            robot.name = slack_user.real_name
            robot.mention_name = slack_user.name
          end

          def metadata(slack_user)
            meta = (slack_user.metadata['profile'] || {}).select do |key, value|
              # Suppress invalid profile attributes:
              #
              # "Data that has not been supplied may not be present at all,
              # may be null or may contain the empty string ("")."
              # https://api.slack.com/methods/users.list
              #
              # Also reject empty arrays: https://github.com/litaio/lita-slack/issues/57
              not value.nil? || value == '' || value.is_a?(Array) && value.compact.empty?
            end

            meta[:name] = real_name(slack_user)
            meta[:mention_name] = slack_user.name
            meta
          end
        end
      end
    end
  end
end
