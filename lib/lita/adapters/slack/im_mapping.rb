module Lita
  module Adapters
    class Slack < Adapter
      class IMMapping
        def initialize(api)
          @api = api
          @ims = {}
        end

        def create_im(im_data)
          ims[im_data["user"]] = im_data["id"]
        end

        def create_ims(ims_data)
          ims_data.each { |im_data| create_im(im_data) }
        end

        def im_for(user_id)
          ims.fetch(user_id) do
            im = api.im_open(user_id)
            ims[user_id] = im.id
          end
        end

        private

        attr_reader :api
        attr_reader :ims
      end
    end
  end
end
