module Lita
  module Adapters
    class Slack < Adapter
      class SlackUser
        class << self
          def from_data(user_data)
            new(
              user_data['id'],
              user_data['name'],
              user_data['real_name'],
              user_data
            )
          end

          def from_data_array(users_data)
            users_data.map { |user_data| from_data(user_data) }
          end
        end

        attr_reader :id
        attr_reader :name
        attr_reader :real_name
        attr_reader :raw_data

        def initialize(id, name, real_name, raw_data)
          @id = id
          @name = name
          @real_name = real_name.to_s
          @raw_data = raw_data
        end
      end
    end
  end
end
