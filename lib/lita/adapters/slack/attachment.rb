module Lita
  module Adapters
    class Slack < Adapter
      # A Slack attachment object.
      # @api public
      # @see https://api.slack.com/docs/attachments
      # @since 1.6.0
      class Attachment
        # @param text [String] The main text of the message.
        # @param options [Hash] Keyword arguments supporting all the option supported by Slack's
        #   attachment API. These options will be passed to Slack as provided, with the exception
        #   that the +:fallback+ option defaults to the value of +text+ (the first argument to this
        #   method) and any value specified for the +:text+ option will be overwritten by the
        #   explicit +text+ argument.
        def initialize(text, **options)
          self.text = text
          self.options = options
        end

        # Converts the attachment into a hash, suitable for being sent to the Slack API.
        # @return [Hash] The converted hash.
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
