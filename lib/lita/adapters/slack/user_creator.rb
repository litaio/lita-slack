module Lita
  module Adapters
    class Slack < Adapter
      class UserCreator
        class << self
          def create_user(user_data, robot, robot_id)
            User.create(
              user_data["id"],
              name: real_name(user_data),
              mention_name: user_data["name"]
            )
          end

          def create_users(users_data, robot, robot_id)
            users_data.each { |user_data| create_user(user_data, robot, robot_id) }
          end

          private

          def real_name(user_data)
            real_name = user_data.fetch("profile", {})["real_name"].to_s
            real_name.size > 0 ? real_name : user_data["name"]
          end
        end
      end
    end
  end
end
