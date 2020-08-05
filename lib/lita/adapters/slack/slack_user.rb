module Lita
  module Adapters
    class Slack < Adapter
      # A struct representing a Slack user.
      # @api public
      class SlackUser
        class << self
          # @api private
          def from_data(user_data)
            new(
              user_data['id'],
              user_data['name'],
              user_data['real_name'],
              user_data
            )
          end

          # @api private
          def from_data_array(users_data)
            users_data.map { |user_data| from_data(user_data) }
          end
        end

        # @return [String] The user's unique ID.
        attr_reader :id
        # @return [String] The user's mention name, e.g. @alice.
        attr_reader :name
        # @return [String] The user's display name, e.g. Alice Bobhart
        attr_reader :real_name
        # @return [String] The user's email address, e.g. alice@example.com
        attr_reader :email
        # @return [Hash] The raw user data received from Slack, including many more fields.
        attr_reader :metadata

        def initialize(id, name, real_name, metadata)
          @id = id
          @name = name
          @real_name = real_name.to_s
          @email = metadata['profile'] && metadata['profile']['email'].to_s
          @metadata = metadata
        end

        # nodoc: backward compatability
        alias_method :raw_data, :metadata
      end
    end
  end
end
