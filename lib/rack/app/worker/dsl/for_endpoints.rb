module Rack::App::Worker::DSL::ForEndpoints

  def workers
    Rack::App::Worker::Register::Clients
  end

end