require 'eventmachine'
require 'faye/websocket'
require 'multi_json'

require 'lita/adapters/slack/api'
require 'lita/adapters/slack/im_mapping'
require 'lita/adapters/slack/message_handler'
require 'lita/adapters/slack/user_creator'

module Lita
  module Adapters
    class Slack < Adapter
      class RTMConnection
        # MAX_MESSAGE_BYTES = 15_000
        MAX_MESSAGE_BYTES = 160

        class << self
          def build(robot, config)
            new(robot, config, API.new(config).rtm_start)
          end
        end

        def initialize(robot, config, team_data)
          @robot = robot
          @config = config
          @im_mapping = IMMapping.new(API.new(config), team_data.ims)
          @websocket_url = team_data.websocket_url
          @robot_id = team_data.self.id

          UserCreator.create_users(team_data.users, robot, robot_id)
        end

        def im_for(user_id)
          im_mapping.im_for(user_id)
        end

        def run(queue = nil, options = {})
          EM.run do
            log.debug("Connecting to the Slack Real Time Messaging API.")
            @websocket = Faye::WebSocket::Client.new(
              websocket_url,
              nil,
              websocket_options.merge(options)
            )

            websocket.on(:open) { log.debug("Connected to the Slack Real Time Messaging API.") }
            websocket.on(:message) { |event| receive_message(event) }
            websocket.on(:close) do
              log.info("Disconnected from Slack.")
              shut_down
            end
            websocket.on(:error) { |event| log.debug("WebSocket error: #{event.message}") }

            queue << websocket if queue
          end
        end

        def send_messages(channel, strings)
          strings.each do |string|
            websocket.send(safe_payload_for(channel, string))
          end
        end

        def shut_down
          if websocket
            log.debug("Closing connection to the Slack Real Time Messaging API.")
            websocket.close
          end

          EM.stop if EM.reactor_running?
        end

        private

        attr_reader :config
        attr_reader :im_mapping
        attr_reader :robot
        attr_reader :robot_id
        attr_reader :websocket
        attr_reader :websocket_url

        def log
          Lita.logger
        end

        def payload_for(channel, string)
          MultiJson.dump({
            id: 1,
            type: 'message',
            text: string,
            channel: channel
          })
        end

        def receive_message(event)
          data = MultiJson.load(event.data)

          MessageHandler.new(robot, robot_id, data).handle
        end

        def safe_payload_for(channel, string)
          log.debug("string.bytesize: #{string.bytesize}; string.length: #{string.length}; MAX_MESSAGE_BYTES: #{MAX_MESSAGE_BYTES}")
          if string.bytesize > MAX_MESSAGE_BYTES
            log.debug("Cannot send message payload greater than #{MAX_MESSAGE_BYTES} bytes. Truncating message.")
            log.debug("string length before = #{string.length}")
            string = "#{string[0..MAX_MESSAGE_BYTES]} ... (message truncated)"
            log.debug("string length after = #{string.length}")
          end
          payload = payload_for(channel, string)
        end

        def websocket_options
          options = { ping: 10 }
          options[:proxy] = { :origin => config.proxy } if config.proxy
          options
        end
      end
    end
  end
end
