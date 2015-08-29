module Lita
  module Adapters
    class Slack < Adapter
      class Attachment
        def initialize(text)
          self.text = text
        end

        def to_hash
          {
            as_user: true,
            fallback: text,
            text: text,
          }
        end

        private

        attr_accessor :text
      end
    end
  end
end
