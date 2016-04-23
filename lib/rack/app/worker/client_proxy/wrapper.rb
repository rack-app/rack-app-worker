require 'yaml'
class Rack::App::Worker::ClientProxy::Wrapper < BasicObject

  def initialize(exchange)
    @exchange = exchange
  end

  protected

  def method_missing(method_name, *args)
    headers = {'method_name' => method_name.to_s}
    @exchange.publish(::YAML.dump(args), :headers => headers)
    nil
  end

end