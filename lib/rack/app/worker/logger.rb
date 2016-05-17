require 'logger'
class Rack::App::Worker::Logger

  def initialize
    @logger = ::Logger.new($stdout)
    @logger.level= Rack::App::Worker::Environment.log_level
  end

  [:debug, :info, :warn, :error, :fatal, :unknown].each do |severity_level|
    define_method(severity_level) { |message| @logger.public_send(severity_level, message) }
  end

end