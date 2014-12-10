module Lita
  module Adapters
    class Slack < Adapter
      class IMMapping
        def initialize(api, ims)
          @api = api
          @mapping = {}

          add_mappings(ims)
        end

        def add_mapping(im)
          mapping[im.user_id] = im.id
        end

        def add_mappings(ims)
          ims.each { |im| add_mapping(im) }
        end

        def im_for(user_id)
          mapping.fetch(user_id) do
            im = api.im_open(user_id)
            mapping[user_id] = im.id
          end
        end

        private

        attr_reader :api
        attr_reader :mapping
      end
    end
  end
end
