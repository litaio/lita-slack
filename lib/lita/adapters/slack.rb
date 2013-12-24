require "lita"
require 'sinatra'
require 'json'

class SlackWebService < Sinatra::Base

get 

end




module Lita
  module Adapters
    class Slack < Adapter
      
      #require_configs :username, :password

      # Start web server for Slack Outgoing WebHook
      def run
      
      end
    end

    Lita.register_adapter(:slack, Slack)
  end
end
