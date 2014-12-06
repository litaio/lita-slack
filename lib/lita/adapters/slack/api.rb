require 'faraday'

module Lita
  module Adapters
    class Slack < Adapter
      class API
        attr_reader :error
        attr_reader :users
        attr_reader :ws_url

        def initialize(token)
          @token = token
        end

        def rtm_start
          response_data = call_api

          @error = error_message_for(response["error"]) unless response["ok"]
          @users = response["users"]
          @ws_url = response["url"]
        end

        private

        attr_reader :token

        def call_api(method, post_data = {})
          response = Faraday.post('https://slack.com/api/rtm.start', token: token)

          raise "Slack API call failed with status code #{response.status}" unless response.success?

          MultiJson.load(response.body)
        end

        def error_message_for(error_type)
          case error
          when "not_authed"
            "No authentication token was provided to Slack."
          when "invalid_auth"
            "The Slack authentication token provided was not valid."
          when "account_inactive"
            "The user or team associated with the provided authentication token has been deleted."
          else
            "An unknown error connecting to Slack."
          end
        end
      end
    end
  end
end
