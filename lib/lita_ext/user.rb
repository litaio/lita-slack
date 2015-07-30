# Monkey patch for slack `User` class to add support for searching for users by e-mail.

class Lita::User
  save_method = self.instance_method(:save)

  define_method(:save) do
    raise 'Error with monkey patch for `User#save` - expected arity to be 0, ' +
        "but it is #{save_method.arity}" unless save_method.arity == 0

    # Call the original
    save_method.bind(self).call

    email = metadata[:email] || metadata["email"]

    # Now save the user's email address as well.
    redis.set("email:#{email}", id) if email
  end

  # Finds a user by e-mail address.
  # @param email [String] The user's e-mail address.
  # @return [Lita::User, nil] The user or +nil+ if no such user is known.
  def self.find_by_email(email)
    id = redis.get("email:#{email}")
    find_by_id(id) if id
  end
end

