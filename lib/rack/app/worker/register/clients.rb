require 'rack/app/worker'
module Rack::App::Worker::Register::Clients

  extend(self)

  def [](name)
    Rack::App::Worker::Register[name][:client]
  end

end
