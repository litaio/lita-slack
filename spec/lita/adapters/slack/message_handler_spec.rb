require "spec_helper"

describe Lita::Adapters::Slack::MessageHandler, lita: true do
  subject { described_class.new(robot, robot_id, data) }

  before do
    allow(robot).to receive(:trigger)
    Lita::Adapters::Slack::RoomCreator.create_room(channel, robot)
  end

  let(:robot) { instance_double('Lita::Robot', name: 'Lita', mention_name: 'lita') }
  let(:robot_id) { 'U12345678' }
  let(:channel) { Lita::Adapters::Slack::SlackChannel.new('C2147483705', 'general', 1360782804, 'U023BECGF', raw_data) }
  let(:raw_data) { Hash.new }

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
          "text" => "Hello",
          "ts" => "1234.5678"
        }
      end
      let(:message) { instance_double('Lita::Message', command!: false, extensions: {}) }
      let(:source) { instance_double('Lita::Source', private_message?: false) }
      let(:user) { instance_double('Lita::User', id: 'U023BECGF') }

      before do
        allow(Lita::User).to receive(:find_by_id).and_return(user)
        allow(Lita::Source).to receive(:new).with(
          user: user,
          room: "C2147483705"
        ).and_return(source)
        allow(Lita::Message).to receive(:new).with(robot, "Hello", source).and_return(message)
        allow(robot).to receive(:receive).with(message)
      end

      it "dispatches the message to Lita" do
        expect(robot).to receive(:receive).with(message)
        subject.handle
      end

      it "saves the timestamp in extensions" do
        subject.handle
        expect(message.extensions[:slack][:timestamp]).to eq("1234.5678")
      end

      context "when the message is a direct message" do
        let(:data) do
          {
            "type" => "message",
            "channel" => "D2147483705",
            "user" => "U023BECGF",
            "text" => "Hello"
          }
        end

        before do
          allow(Lita::Source).to receive(:new).with(
            user: user,
            room: "D2147483705"
          ).and_return(source)
          allow(source).to receive(:private_message!).and_return(true)
          allow(source).to receive(:private_message?).and_return(true)
        end

        it "marks the source as a private message" do
          expect(source).to receive(:private_message!)

          subject.handle
        end

        it "marks the message as a command" do
          expect(message).to receive(:command!)

          subject.handle
        end
      end

      context "when the message starts with a Slack-style @-mention" do
        let(:data) do
          {
            "type" => "message",
            "channel" => "C2147483705",
            "user" => "U023BECGF",
            "text" => "<@#{robot_id}>: Hello"
          }
        end

        it "converts it to a Lita-style @-mention" do
          expect(Lita::Message).to receive(:new).with(
            robot,
            "@lita: Hello",
            source
          ).and_return(message)

          subject.handle
        end
      end

      context "when the message has attach" do
        let(:data) do
          {
            "type" => "message",
            "channel" => "C2147483705",
            "user" => "U023BECGF",
            "text" => "Hello",
            "attachments" => [{"text" => "attached hello"}]
          }
        end

        it "recives attachment text" do
          expect(Lita::Message).to receive(:new).with(
            robot,
            "Hello\nattached hello",
            source
          ).and_return(message)

          subject.handle
        end
      end

      context "when the message is nil" do
        let(:data) do
          {
            "type" => "message",
            "channel" => "C2147483705",
            "user" => "U023BECGF",
          }
        end

        it "dispatches an empty message to Lita" do
          expect(Lita::Message).to receive(:new).with(
            robot,
            "",
            source
          ).and_return(message)

          subject.handle
        end
      end

      describe "Removing message formatting" do

        let(:user) { instance_double('Lita::User', id: 'U123',name: 'name', mention_name: 'label') }

        context "does nothing if there are no user links" do
          let(:data) do
            {
                "type"    => "message",
                "channel" => "C2147483705",
                "text"    => "foo",
            }
          end

          it "removes formatting" do
            expect(Lita::Message).to receive(:new).with(
                                         robot,
                                         "foo",
                                         source
                                     ).and_return(message)

            subject.handle
          end

        end
        context "decodes entities" do
          let(:data) do
            {
                "type"    => "message",
                "channel" => "C2147483705",
                "text"    => "foo &gt; &amp; &lt; &gt;&amp;&lt;",
            }
          end

          it "removes formatting" do
            expect(Lita::Message).to receive(:new).with(
                                         robot,
                                         "foo > & < >&<",
                                         source
                                     ).and_return(message)

            subject.handle
          end

        end

        context "changes <@123> links to @label" do
          let(:data) do
            {
                "type"    => "message",
                "channel" => "C2147483705",
                "text"    => "foo <@123> bar",
            }
          end
          it "removes formatting" do
            expect(Lita::Message).to receive(:new).with(
                                         robot,
                                         "foo @label bar",
                                         source
                                     ).and_return(message)

            subject.handle
          end
        end

        context "changes <@U123|label> links to label" do
          let(:data) do
            {
                "type"    => "message",
                "channel" => "C2147483705",
                "text"    => "foo <@123|label> bar",
            }
          end
          it "removes formatting" do
            expect(Lita::Message).to receive(:new).with(
                                         robot,
                                         "foo label bar",
                                         source
                                     ).and_return(message)

            subject.handle
          end
        end

        context "changes <#C2147483705> links to #general" do
          let(:data) do
            {
                "type"    => "message",
                "channel" => "C2147483705",
                "text"    => "foo <#C2147483705> bar",
            }
          end
          it "removes formatting" do
            expect(Lita::Message).to receive(:new).with(
                                         robot,
                                         "foo #general bar",
                                         source
                                     ).and_return(message)

            subject.handle
          end
        end

        context "changes <#C2147483705|genral> links to #general" do
          let(:data) do
            {
                "type"    => "message",
                "channel" => "C2147483705",
                "text"    => "foo <#C2147483705|general> bar",
            }
          end
          it "removes formatting" do
            expect(Lita::Message).to receive(:new).with(
                                         robot,
                                         "foo general bar",
                                         source
                                     ).and_return(message)

            subject.handle
          end
        end

        context "changes <!everyone> links to @everyone" do
          let(:data) do
            {
                "type"    => "message",
                "channel" => "C2147483705",
                "text"    => "foo <!everyone> bar",
            }
          end
          it "removes formatting" do
            expect(Lita::Message).to receive(:new).with(
                                         robot,
                                         "foo @everyone bar",
                                         source
                                     ).and_return(message)
            subject.handle
          end
        end

        context "changes  <!channel> links to @channel" do
          let(:data) do
            {
                "type"    => "message",
                "channel" => "C2147483705",
                "text"    => "foo <!channel> bar",
            }
          end
          it "removes formatting" do
            expect(Lita::Message).to receive(:new).with(
                                         robot,
                                         "foo @channel bar",
                                         source
                                     ).and_return(message)
            subject.handle
          end
        end

        context "changes <!group> links to @group" do
          let(:data) do
            {
                "type"    => "message",
                "channel" => "C2147483705",
                "text"    => "foo <!group> bar",
            }
          end
          it "removes formatting" do
            expect(Lita::Message).to receive(:new).with(
                                         robot,
                                         "foo @group bar",
                                         source
                                     ).and_return(message)
            subject.handle
          end
        end

        context "removes remove formatting around <http> links" do
          let(:data) do
            {
                "type"    => "message",
                "channel" => "C2147483705",
                "text"    => "foo <http://www.example.com> bar",
            }
          end
          it "removes formatting" do
            expect(Lita::Message).to receive(:new).with(
                                         robot,
                                         "foo http://www.example.com bar",
                                         source
                                     ).and_return(message)
            subject.handle
          end
        end

        context "removes remove formatting around <http> links with a substring label" do
          let(:data) do
            {
                "type"    => "message",
                "channel" => "C2147483705",
                "text"    => "foo <http://www.example.com|www.example.com> bar",
            }
          end
          it "removes formatting" do
            expect(Lita::Message).to receive(:new).with(
                                         robot,
                                         "foo www.example.com bar",
                                         source
                                     ).and_return(message)
            subject.handle
          end
        end

        context "remove formatting around <skype> links" do
          let(:data) do
            {
                "type"    => "message",
                "channel" => "C2147483705",
                "text"    => "foo <skype:echo123?call> bar",
            }
          end
          it "removes formatting" do
            expect(Lita::Message).to receive(:new).with(
                                         robot,
                                         "foo skype:echo123?call bar",
                                         source
                                     ).and_return(message)
            subject.handle
          end
        end

        context "remove formatting around <http> links with a label containing entities" do
          let(:data) do
            {
                "type"    => "message",
                "channel" => "C2147483705",
                "text"    => "foo <http://www.example.com|label &gt; &amp; &lt;> bar",
            }
          end
          it "removes formatting" do
            expect(Lita::Message).to receive(:new).with(
                                         robot,
                                         "foo label > & < (http://www.example.com) bar",
                                         source
                                     ).and_return(message)
            subject.handle
          end
        end

        context "remove formatting around around <mailto> links" do
          let(:data) do
            {
                "type"    => "message",
                "channel" => "C2147483705",
                "text"    => "foo <mailto:name@example.com> bar",
            }
          end
          it "removes formatting" do
            expect(Lita::Message).to receive(:new).with(
                                         robot,
                                         "foo name@example.com bar",
                                         source
                                     ).and_return(message)
            subject.handle
          end
        end

        context "remove formatting around <mailto> links with an email label" do
          let(:data) do
            {
                "type"    => "message",
                "channel" => "C2147483705",
                "text"    => "foo <mailto:name@example.com|name@example.com> bar",
            }
          end
          it "removes formatting" do
            expect(Lita::Message).to receive(:new).with(
                                         robot,
                                         "foo name@example.com bar",
                                         source
                                     ).and_return(message)
            subject.handle
          end
        end

        context "change multiple links at once" do
          let(:data) do
            {
                "type"    => "message",
                "channel" => "C2147483705",
                "text"    => "foo <@U123|label> bar <#C2147483705> <!channel> <http://www.example.com|label>",
            }
          end
          it "removes formatting" do
            expect(Lita::Message).to receive(:new).with(
                                         robot,
                                         "foo label bar #general @channel label (http://www.example.com)",
                                         source
                                     ).and_return(message)
            subject.handle
          end
        end


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
      # let(:bobby) { Lita::Adapters::Slack::SlackUser.new('U023BECGF', 'bobby', real_name) }
      let(:data) do
        {
          "type" => "team_join",
          "user" => {
            "id" => "U023BECGF",
            "name" => "bobby",
            "real_name" => "Bobby Tables"
          }
        }
      end

      it "creates the new user" do
        expect(
          Lita::Adapters::Slack::UserCreator
        ).to receive(:create_user) do |slack_user, robot, robot_id|
          expect(slack_user.name).to eq("bobby")
        end

        subject.handle
      end
    end

    context "with a bot added message" do
      let(:data) do
        {
          "type" => "bot_added",
          "bot" => {
            "id" => "U01234567",
            "name" => "foobot"
          }
        }
      end

      it "creates a new user for the bot" do
        expect(
          Lita::Adapters::Slack::UserCreator
        ).to receive(:create_user) do |slack_user, robot, robot_id|
          expect(slack_user.name).to eq("foobot")
        end

        subject.handle
      end
    end

    %w(channel_created channel_rename group_rename).each do |type|
      context "with a #{type} message" do
        before { allow(robot).to receive(:trigger) }

        let(:data) do
          {
            "type" => type,
            "channel" => {
              "id" => "C01234567890",
              "name" => "mychannel",
            }
          }
        end

        it "creates a new room for the channel" do
          subject.handle

          expect(Lita::Room.find_by_name("mychannel").id).to eq('C01234567890')
        end
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

    context "with a reaction_added message" do
      let(:data) do
        {
          "type" => "reaction_added",
          "user" => "U023BECGF",
          "item"=>{"type"=>"message", "channel"=>"C2147483705", "ts"=>"1234567.000008"},
          "reaction"=>"+1",
          "event_ts"=>"1234.5678"
        }
      end
      let(:reaction) { instance_double('Lita::Adapters::Slack::Reaction', extensions: {}) }
      let(:source) { instance_double('Lita::Source') }
      let(:user) { instance_double('Lita::User', id: 'U023BECGF') }

      before do
        allow(Lita::User).to receive(:find_by_id).and_return(user)
        allow(Lita::Source).to receive(:new).with(
            user: user,
            room: "C2147483705"
          ).and_return(source)
        allow(Lita::Adapters::Slack::Reaction).to receive(:new)
            .with(robot, "+1", {"type"=>"message", "channel"=>"C2147483705", "ts"=>"1234567.000008"}, source, "added").and_return(reaction)
        allow(robot).to receive(:receive).with(reaction)
      end

      it "dispatches the added reaction to Lita" do
        expect(robot).to receive(:receive).with(reaction)
        subject.handle
      end

      it "saves the timestamp in extensions" do
        subject.handle
        expect(reaction.extensions[:slack][:timestamp]).to eq("1234.5678")
      end
    end

    context "with a reaction_removed message" do
      let(:data) do
        {
          "type" => "reaction_removed",
          "user" => "U023BECGF",
          "item"=>{"type"=>"message", "channel"=>"C2147483705", "ts"=>"1234567.000008"},
          "reaction"=>"+1",
          "event_ts"=>"1234.5678"
        }
      end
      let(:reaction) { instance_double('Lita::Adapters::Slack::Reaction', extensions: {}) }
      let(:source) { instance_double('Lita::Source') }
      let(:user) { instance_double('Lita::User', id: 'U023BECGF') }

      before do
        allow(Lita::User).to receive(:find_by_id).and_return(user)
        allow(Lita::Source).to receive(:new).with(
            user: user,
            room: "C2147483705"
          ).and_return(source)
        allow(Lita::Adapters::Slack::Reaction).to receive(:new)
            .with(robot, "+1", {"type"=>"message", "channel"=>"C2147483705", "ts"=>"1234567.000008"}, source, "removed").and_return(reaction)
        allow(robot).to receive(:receive).with(reaction)
      end

      it "dispatches the removed reaction to Lita" do
        expect(robot).to receive(:receive).with(reaction)
        subject.handle
      end

      it "saves the timestamp in extensions" do
        subject.handle
        expect(reaction.extensions[:slack][:timestamp]).to eq("1234.5678")
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
