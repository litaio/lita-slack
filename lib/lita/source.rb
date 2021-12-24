module Lita
  class Source

    # The room the message came from or should be sent to, as a string.
    # @return [String, NilClass] A string uniquely identifying the room.
    attr_reader :thread

    # @param user [Lita::User] The user who sent the message or should receive
    #   the outgoing message.
    # @param room [Lita::Room, String] A string or {Lita::Room} uniquely identifying the room
    #   the user sent the message from, or the room where a reply should go. The format of this
    #   string (or the ID of the {Lita::Room} object) will differ depending on the chat service.
    # @param private_message [Boolean] A flag indicating whether or not the
    #   message was sent privately.
    def initialize(user: nil, room: nil, thread: nil, private_message: false)
      @user = user
      @thread = thread

      case room
      when String
        @room = room
        @room_object = Room.new(room)
      when Room
        @room = room.id
        @room_object = room
      end

      @private_message = private_message

      raise ArgumentError, I18n.t("lita.source.user_or_room_required") if user.nil? && room.nil?

      @private_message = true if room.nil?
    end
  end
end
