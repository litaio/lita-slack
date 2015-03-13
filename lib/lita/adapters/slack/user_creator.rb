module Lita
  module Adapters
    class Slack < Adapter
      class UserCreator
        class << self
          def create_user(slack_user, robot, robot_id)
            User.create(
              slack_user.id,
              name: real_name(slack_user),
              mention_name: slack_user.name
            )

            update_robot(robot, slack_user) if slack_user.id == robot_id
            robot.trigger(:slack_user_created, user_id: slack_user.id, raw_data: slack_user.raw_data)
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
        end
      end
    end
  end
end
