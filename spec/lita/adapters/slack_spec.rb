require "spec_helper"

describe Lita::Adapters::Slack do
	before do
		Lita.configure do |config|
			config.adapter.incoming_token = 'aN1NvAlIdDuMmYt0k3n'
			config.adapter.team_domain = 'example'
			config.adapter.username = 'lita'
			config.adapter.add_mention = true
		end
	end

	subject { described_class.new(robot) }
	let(:robot) { double("Lita::Robot") }

	it "registers with Lita" do
		expect(Lita.adapters[:slack]).to eql(described_class)
	end
	
	it "fails without valid config: incoming_token and team_domain" do
		Lita.clear_config
		expect(Lita.logger).to receive(:fatal).with(/incoming_token, team_domain/)
		expect { subject }.to raise_error(SystemExit)
	end
	
	describe "#send_messages" do
		it "sends JSON payload via HTTP POST to Slack channel" do
			target = double("Lita::Source", room: "CR00M1D")
			payload = {'channel' => target.room, 'username' => Lita.config.adapter.username, 'text' => 'Hello!'}
			expect(subject).to receive(:http_post).with(payload)
			subject.send_messages(target, ["Hello!"])
		end

		it "sends message with mention if user info is provided" do
			user = double("Lita::User", id: "UM3NT10N")
			target = double("Lita::Source", room: "CR00M1D", user: user)
			text = "<@#{user.id}> Hello!"
			payload = {'channel' => target.room, 'username' => Lita.config.adapter.username, 'text' => text}
			expect(subject).to receive(:http_post).with(payload)
			subject.send_messages(target, ["Hello!"])
		end

		it "proceeds but logs WARN when directed to an user without channel(room) info" do
			user = double("Lita::User", id: "UM3NT10N")
			target = double("Lita::Source", user: user)
			text = "<@#{user.id}> Hello!"
			payload = {'channel' => nil, 'username' => Lita.config.adapter.username, 'text' => text}
			expect(subject).to receive(:http_post).with(payload)
			expect(Lita.logger).to receive(:warn).with(/without channel/)
			subject.send_messages(target, ["Hello!"])
		end
	end
end
