require 'logger'
class Rack::App::Worker::Logger

  def self.default_out(new_out=nil)
    @default_out = new_out unless new_out.nil?
    @default_out ||= $stdout
  end

  def initialize(out=self.class.default_out)
    @logger = ::Logger.new(out)
    @logger.level= Rack::App::Worker::Environment.log_level
  end

  [:debug, :info, :warn, :error, :fatal, :unknown].each do |severity_level|
    define_method(severity_level) { |message| @logger.public_send(severity_level, message) }
  end

end