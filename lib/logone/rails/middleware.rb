require_relative "logger"
require 'logger'

module Logone
  module Rails
    class Middleware
      def initialize(app, filename = "")
        @app = app
        @logdev = ::Logger::LogDevice.new(filename)
        @logger = Logone::Rails::Logger.new(@logdev)
        ::Rails.logger = @logger
      end
      def call(env)
        ::Rails.logger.start()
        status, headers, body = @app.call(env)
      ensure
        ::Rails.logger.end(env, status, headers)
        [status, headers, body]
      end
    end
  end
end
