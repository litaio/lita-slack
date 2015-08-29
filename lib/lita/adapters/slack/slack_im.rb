module Lita
  module Adapters
    class Slack < Adapter
      # @api private
      class SlackIM
        class << self
          def from_data_array(ims_data)
            ims_data.map { |im_data| from_data(im_data) }
          end

          def from_data(im_data)
            new(im_data['id'], im_data['user'])
          end
        end

        attr_reader :id
        attr_reader :user_id

        def initialize(id, user_id)
          @id = id
          @user_id = user_id
        end
      end
    end
  end
end

