module Lita
  module Adaptesr
    class Slack < Adapter
      class IMOpenResponse < Struct.new(:error_type, :id)
        def self.build(data)
          new(
            data.fetch("error") { nil }
            data.fetch("channel").fetch("id")
          )
        end

        def error
          case error_type
          when "user_not_found"
            "The provided user value was invalid."
          when "user_not_visible"
            "Lita is not allowed to see the specified user."
          when "not_authed"
            "No authentication token was provided to Slack."
          when "invalid_auth"
            "The Slack authentication token provided was not valid."
          when "account_inactive"
            "The user or team associated with the provided authentication token has been deleted."
          else
            "An unknown error occurred opening the IM."
          end
        end
      end
    end
  end
end

