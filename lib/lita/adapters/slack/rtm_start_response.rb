module Lita
  module Adapters
    class Slack < Adapter
      class RTMStartResponse < Struct.new(:error_type, :ims, :users, :websocket_url)
        def self.build(data)
          new(
            data.fetch("error") { nil },
            data.fetch("ims"),
            data.fetch("users"),
            data.fetch("url")
          )
        end

        def error
          return unless error_type
          case error_type
          when "not_authed"
            "No authentication token was provided to Slack."
          when "invalid_auth"
            "The Slack authentication token provided was not valid."
          when "account_inactive"
            "The user or team associated with the provided authentication token has been deleted."
          else
            "An unknown error occurred connecting to Slack."
          end
        end
      end
    end
  end
end
