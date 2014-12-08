module Lita
  module Adaptesr
    class Slack < Adapter
      class RTMStartResponse < Struct.new(:error_type, :users, :websocket_url, :ims)
        def self.build(data)
          new(
            data.fetch("error") { nil },
            data.fetch("users"),
            data.fetch("ims"),
            data.fetch("url")
          )
        end

        def error
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
