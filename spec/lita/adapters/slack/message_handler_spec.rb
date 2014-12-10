require "spec_helper"

describe Lita::Adapters::Slack::MessageHandler, lita: true do
  subject { described_class.new(robot, data) }

  let(:robot) { instance_double('Lita::Robot', name: 'Lita') }

  describe "#handle" do
    context "with a hello message" do
      let(:data) { { "type" => "hello" } }

      it "triggers a connected event" do
        expect(robot).to receive(:trigger).with(:connected)

        subject.handle
      end
    end

    context "with a normal message" do
      let(:data) do
        {
          "type" => "message",
          "channel" => "C2147483705",
          "user" => "U023BECGF",
          "text" => "Hello"
        }
      end
      let(:message) { instance_double('Lita::Message') }
      let(:source) { instance_double('Lita::Source') }
      let(:user) { instance_double('Lita::User', id: 'U023BECGF') }

      before do
        allow(Lita::User).to receive(:find_by_id).and_return(user)
        allow(Lita::Source).to receive(:new).with(
          user: user,
          room: "C2147483705"
        ).and_return(source)
        allow(Lita::Message).to receive(:new).with(robot, "Hello", source).and_return(message)
      end

      it "dispatches the message to Lita" do
        expect(robot).to receive(:receive).with(message)

        subject.handle
      end
    end

    context "with a message with an unsupported subtype" do
      let(:data) do
        {
          "type" => "message",
          "subtype" => "???"
        }
      end

      it "does not dispatch the message to Lita" do
        expect(robot).not_to receive(:receive)

        subject.handle
      end
    end

    context "with a message from the robot itself" do
      let(:data) do
        {
          "type" => "message",
          "subtype" => "bot_message"
        }
      end
      let(:user) { instance_double('Lita::User', id: 12345) }

      before do
        # TODO: This probably shouldn't be tested with stubs.
        allow(Lita::User).to receive(:find_by_id).and_return(user)
        allow(Lita::User).to receive(:find_by_name).and_return(user)
      end

      it "does not dispatch the message to Lita" do
        expect(robot).not_to receive(:receive)

        subject.handle
      end
    end

    context "with a team join message" do
      let(:data) do
        {
          "type" => "team_join",
          "user" => "some user data"
        }
      end

      it "creates the new user" do
        expect(
          Lita::Adapters::Slack::UserCreator
        ).to receive(:create_user).with("some user data")

        subject.handle
      end
    end

    context "with a bot added message" do
      let(:data) do
        {
          "type" => "bot_added",
          "bot" => "some user data"
        }
      end

      it "creates a new user for the bot" do
        expect(
          Lita::Adapters::Slack::UserCreator
        ).to receive(:create_user).with("some user data")

        subject.handle
      end
    end

    context "with an error message" do
      let(:data) do
        {
          "type" => "error",
          "error" => {
            "code" => 2,
            "msg" => "message text is missing"
          }
        }
      end

      it "logs the error" do
        expect(Lita.logger).to receive(:error).with(
          "Error with code 2 received from Slack: message text is missing"
        )

        subject.handle
      end
    end

    context "with an unknown message" do
      let(:data) { { "type" => "???" } }

      it "logs the type" do
        expect(Lita.logger).to receive(:debug).with(
          "??? event received from Slack and will be ignored."
        )

        subject.handle
      end
    end
  end
end
