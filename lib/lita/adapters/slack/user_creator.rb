require 'json'

module Lita
  module Adapters
    class Slack < Adapter
      class UserCreator
        class << self
          def create_user(slack_user, robot, robot_id)
            metadata = slack_user.merge(slack_user["profile"]).merge({
              "name" => real_name(slack_user),
              "mention_name" => slack_user['name'],
            })

            metadata.delete("id")
            metadata.delete("profile")

            User.create(slack_user["id"], metadata)

            update_robot(robot, slack_user) if slack_user["id"] == robot_id
          end

          def create_users(slack_users, robot, robot_id)
            slack_users.each { |slack_user| create_user(slack_user, robot, robot_id) }
          end

          private

          def real_name(slack_user)
            if slack_user["real_name"] && !slack_user["real_name"].empty?
              slack_user["real_name"]
            else
              slack_user["name"]
            end
          end

          def update_robot(robot, slack_user)
            robot.name = slack_user["real_name"]
            robot.mention_name = slack_user["name"]
          end
        end
      end
    end
  end
end
