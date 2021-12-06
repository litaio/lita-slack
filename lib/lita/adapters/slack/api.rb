require 'faraday'

require 'lita/adapters/slack/team_data'
require 'lita/adapters/slack/slack_im'
require 'lita/adapters/slack/slack_user'
require 'lita/adapters/slack/slack_channel'

module Lita
  module Adapters
    class Slack < Adapter
      # @api private
      class API
        def initialize(config, stubs = nil)
          @config = config
          @stubs = stubs
          @post_message_config = {}
          @post_message_config[:parse] = config.parse unless config.parse.nil?
          @post_message_config[:link_names] = config.link_names ? 1 : 0 unless config.link_names.nil?
          @post_message_config[:unfurl_links] = config.unfurl_links unless config.unfurl_links.nil?
          @post_message_config[:unfurl_media] = config.unfurl_media unless config.unfurl_media.nil?
        end

        def im_open(user_id)
          response_data = call_api('im.open', user: user_id)

          SlackIM.new(response_data['channel']['id'], user_id)
        end

        def channels_info(channel_id)
          call_api('channels.info', channel: channel_id)
        end

        def conversations_list
          call_api('conversations.list')
        end

        def users_list
          call_api('users.list')
        end

        def groups_list
          call_api('groups.list')
        end

        def mpim_list
          call_api('mpim.list')
        end

        def im_list
          call_api('im.list')
        end

        def send_attachments(room_or_user, attachments)
          call_api(
            'chat.postMessage',
            as_user: true,
            channel: room_or_user.id,
            attachments: MultiJson.dump(attachments.map(&:to_hash))
          )
        end

        def send_messages(channel_id, messages)
          call_api(
            'chat.postMessage',
            **post_message_config,
            as_user: true,
            channel: channel_id,
            text: messages.join("\n")
          )
        end

        def set_topic(channel, topic)
          call_api('channels.setTopic', channel: channel, topic: topic)
        end

        def rtm_start
          rtm_response_data = call_api('rtm.connect')

          users_response_data = users_list
          conversations_response_data = conversations_list

          channels = conversations_response_data['channels'].select { |c| c['is_channel'] }
          groups = conversations_response_data['channels'].select { |c| c['is_group'] }
          ims    = conversations_response_data['channels'].select { |c| c['is_im'] }

          TeamData.new(
            SlackIM.from_data_array(ims), # ims
            SlackUser.from_data(rtm_response_data['self']), # self
            SlackUser.from_data_array(users_response_data['members']), # users
            SlackChannel.from_data_array(channels) +
              SlackChannel.from_data_array(groups), # channels
            rtm_response_data['url'] # websocket_url
          )
        end

        private

        attr_reader :stubs, :config, :post_message_config

        def call_api(method, post_data = {})
          response = connection.post(
            "https://slack.com/api/#{method}",
            { token: config.token }.merge(post_data)
          )

          data = parse_response(response, method)

          raise "Slack API call to #{method} returned an error: #{data['error']}." if data['error']

          data
        end

        def connection
          if stubs
            Faraday.new { |faraday| faraday.adapter(:test, stubs) }
          else
            options = {}
            options = { proxy: config.proxy } unless config.proxy.nil?
            Faraday.new(options)
          end
        end

        def parse_response(response, method)
          unless response.success?
            raise "Slack API call to #{method} failed with status code #{response.status}: '#{response.body}'. Headers: #{response.headers}"
          end

          MultiJson.load(response.body)
        end
      end
    end
  end
end
