module Logone
  module Rails
    class LogEntry
      attr_reader :log
      def initialize
        @log = []
      end
      def add(severity, message = nil, call = nil)
        line = {}
        line[:severity] = severity
        line[:logMessage] = message
        line[:time] = Time.now.utc.iso8601(6)
        if call
          filename, fileline, method = parse_caller(call)
          line[:filename] = filename
          line[:fileline] = fileline
          line[:method] = method
        end
        @log << line
      end

      def parse_caller(at)
        if /^(.+?):(\d+)(?::in `(.*)')?/ =~ at
          file = $1
          line = $2.to_i
          method = $3
          return file, line, method
        end
      end
    end
  end
end

