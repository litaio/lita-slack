module Lita
  module Adapters
    class Slack < Adapter
      class Attachment
        def initialize(text, fallback: nil)
          self.text = text
          self.fallback = fallback
        end

        def to_hash
          {
            as_user: true,
            fallback: fallback || text,
            text: text,
          }
        end

        private

        attr_accessor :fallback
        attr_accessor :text
      end
    end
  end
end
