require 'time'
require 'json'
require_relative 'logentry'

module Logone
  module Rails
    class Logger
      attr_accessor :formatter # not implementation
      attr_accessor :level # not implementation

      def initialize(logdev)
        @logdev = logdev
        @formatter = '' # not implementation
        @level = 'debug' # not implementation
      end

      def thread_val
        thread_key = @thread_key ||= "Logone::Rails::#{object_id}".freeze
        Thread.current[thread_key] ||= {}
      end

      def set(key, value)
        thread_val[key] = value
      end

      def get(key)
        thread_val[key]
      end

      def start()
        thread_val.clear
        set("severity", "DEBUG")
        set("logline", Logone::Rails::LogEntry.new)
        set("startTime", Time.now)
      end

      def write(requestlog)
        @logdev.write(requestlog.to_json + "\n")
      rescue
        STDERR.puts(requestlog)
      end

      def end(env, status, headers)
        headers ||= {}
        endTime = Time.now

        requestlog = {
          :startTime        => get('startTime').utc.iso8601(6),
          :endTime          => endTime.utc.iso8601(6),
          :latency          => (endTime - get('startTime')).to_s + "s",
          :status           => status || "-",
          :responseSize     => "-",
          :userAgent        => env["HTTP_USER_AGENT"],
          :host             => env["HTTP_HOST"],
          :method           => env["REQUEST_METHOD"],
          :resource         => env["REQUEST_URI"],
          :httpVersion      => env["HTTP_VERSION"],
          :line             => get('logline').log,
          :severity         => get('severity'),
        }
        if value = (headers && headers['Content-Length'])
          requestlog[:responseSize] = value
        end
        write(requestlog)
      ensure
        thread_val.clear
      end

      def debug?; true; end
      def debug!; true; end
      def info?; true; end
      def info!; true; end
      def warn?; true; end
      def warn!; true; end
      def error?; true; end
      def error!; true; end
      def fatal?; true; end
      def fatal!; true; end
      
      def addLine(severity, message = nil, progname = nil, call = nil)
        severity ||= "UNKNOWN"
        if call.nil?
          call = caller(1)
        end
        #if @logdev.nil? or severity < level
        #  return true
        #end
        if progname.nil?
          progname = @progname
        end
        if message.nil?
          if block_given?
            message = yield
          else
            message = progname
            progname = @progname
          end
        end
        set('severity', calc_severity(get('severity'), severity))
        get('logline').add(severity, message, call)
        true
      end

      def debug(progname = nil, &block)
        addLine("DEBUG", nil, progname, caller.first, &block)
      end

      def info(progname = nil, &block)
        addLine("INFO", nil, progname, caller.first, &block)
      end

      def warn(progname = nil, &block)
        addLine("WARN", nil, progname, caller.first, &block)
      end

      def error(progname = nil, &block)
        addLine("ERROR", nil, progname, caller.first, &block)
      end

      def fatal(progname = nil, &block)
        addLine("FATAL", nil, progname, caller.first, &block)
      end

      def unknown(progname = nil, &block)
        addLine("UNKNOWN", nil, progname, caller.first, &block)
      end
      

      # 本当は頭良くやりたいけどもとりあえず
      # https://github.com/ruby/logger/blob/master/lib/logger/severity.rb
      def calc_severity(prev, current)
        if prev == "CRITICAL"
          return prev
        elsif prev == "ERROR" && current == "CRITICAL"
          return current
        elsif prev == "WARNINGS" && (current == "CRITICAL" || current == "ERROR")
          return current
        elsif prev == "INFO" && (current == "CRITICAL" || current == "ERROR" || current == "WARNING")
          return current
        elsif prev == "DEBUG" && (current == "CRITICAL" || current == "ERROR" || current == "WARNING" || current == "INFO")
          return current
        end
        return current
      end
    end
  end
end
