class Rack::App::Worker::ClientProxy

  require 'rack/app/worker/client_proxy/wrapper'

  def initialize(name)
    @name = name
  end

  def send
    Rack::App::Worker::ClientProxy::Wrapper.new(rabbitmq.send_exchange(@name))
  end

  alias to_one send

  def broadcast
    Rack::App::Worker::ClientProxy::Wrapper.new(rabbitmq.broadcast_exchange(@name))
  end

  alias to_all broadcast

  protected

  def rabbitmq
    @rabbitmq ||= Rack::App::Worker::RabbitMQ.new
  end

end