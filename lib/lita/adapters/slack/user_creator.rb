module Lita
  module Adapters
    class Slack < Adapter
      class UserCreator
        def create_user(user_data)
          User.create(user_data["id"], name: real_name(user_data), mention_name: user_data["name"])
        end

        def create_users(users_data)
          users_data.each { |user_data| create_user(user_data) }
        end

        def real_name(user_data)
          real_name = user_data["real_name"]
          real_name.size > 0 ? real_name : user_data["name"]
        end
      end
    end
  end
end
