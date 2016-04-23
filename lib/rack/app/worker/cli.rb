require 'rack/app/worker'
module Rack::App::Worker::CLI

  extend(self)

  def start(options)
    observer = Rack::App::Worker::Observer.new
    daemonizer.daemonize if options[:daemonize]
    daemonizer.subscribe_to_signals
    # daemonizer.on_shutdown{ observer.stop }
    # daemonizer.on_halt{ observer.stop }
    observer.start
  end

  def stop(options)
    daemonizer.send_signal('HUP')
  end

  def halt(options)
    daemonizer.send_signal('TERM')
  end

  def reload(options)
    daemonizer.send_signal('USR1')
  end

  protected

  def method_missing(command)
    $stderr.puts("Unknown worker command: #{command}")
  end

  def daemonizer
    @daemonizer ||= Rack::App::Worker::Daemonizer.new('master')
  end

end