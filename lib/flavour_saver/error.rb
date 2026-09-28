module FlavourSaver
  # Base class for errors raised when a template can't be lexed or parsed.
  # Rescue this to catch every invalid template.
  class Error < StandardError; end
end
