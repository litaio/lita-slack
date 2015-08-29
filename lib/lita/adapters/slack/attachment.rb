module Lita
  module Adapters
    class Slack < Adapter
      class Attachment
        def initialize(text, **options)
          self.text = text
          self.options = options
        end

        def to_hash
          options.merge({
            fallback: options[:fallback] || text,
            text: text,
          })
        end

        private

        attr_accessor :options
        attr_accessor :text
      end
    end
  end
end
