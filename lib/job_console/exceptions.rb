module JobConsole::Exceptions
  class UnknownCommand < StandardError; end
  class UnknownAccount < StandardError; end
  class UnknownJob < StandardError; end
  class NoFilename < StandardError; end
  class NoOutput < StandardError; end
end
