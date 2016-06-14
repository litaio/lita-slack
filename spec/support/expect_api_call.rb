 module ExpectApiCall
   # Return an API with stubs so we can easily stub network requests
   def token
     'abcd-1234567890-hWYd21AmMH2UHAkx29vb5c1Y'
   end
   def stubs
     @stubs ||= Faraday::Adapter::Test::Stubs.new
   end

   def expect_api_call(method, response: { "ok" => true }, token: self.token, **arguments)
     stubs.post("https://slack.com/api/#{method}", token: token, **arguments) do
       [200, {}, MultiJson.dump(response)]
     end
   end

   def self.included(other)
     other.before do
       registry.config.adapters.slack.token = token
       allow_any_instance_of(Lita::Adapters::Slack::API).to receive(:stubs).and_return(stubs)
     end
   end
end
