require 'rack/app'
module Rack::App::Worker

  require 'rack/app/worker/version'
  require 'rack/app/worker/logger'
  require 'rack/app/worker/utils'

  require 'rack/app/worker/environment'

  require 'rack/app/worker/cli'
  require 'rack/app/worker/dsl'

  require 'rack/app/worker/observer'
  require 'rack/app/worker/consumer'
  require 'rack/app/worker/daemonizer'

  require 'rack/app/worker/register'
  require 'rack/app/worker/client_proxy'

  require 'rack/app/worker/rabbit_mq'

  Rack::App::Extension.register :worker do

    extend Rack::App::Worker::DSL::ForClass
    include Rack::App::Worker::DSL::ForEndpoints

    cli do

      command :workers do

        option '-d','--daemon','--daemonize','Daemonize this process' do
          options[:daemonize]= true
        end

        desc 'manage your defined workers with a simple start/stop/restart command'
        action do |start_or_stop_or_restart|
          Rack::App::Worker::CLI.public_send(start_or_stop_or_restart.downcase, options)
        end

      end

    end

  end

end
