require 'bunny'
require 'rack/app/worker'
class Rack::App::Worker::RabbitMQ

  def session
    check_connection
    @session
  end

  def channel
    @channel ||= create_channel
    @channel = create_channel unless @channel.open?
    @channel
  end

  def send_exchange(name)
    exchange_for('send', name)
  end

  def broadcast_exchange(name)
    exchange_for('broadcast', name)
  end

  def send_queue(name)
    queue_name = "#{namespace}.#{cluster}.#{name}"
    queue = channel.queue(queue_name, :durable => true, :auto_delete => false)
    queue.bind(send_exchange(name)) unless exchange_already_bind?(queue, name)
    return queue
  end

  def create_broadcast_queue(name)
    queue = channel.queue('', :exclusive => true, :auto_delete => false)
    queue.bind(broadcast_exchange(name)) unless exchange_already_bind?(queue, name)
    return queue
  end

  protected

  def exchange_already_bind?(queue, name)
    queue.recover_bindings.any? { |binding| binding[:exchange] == exchange_name('send', name) }
  rescue Timeout::Error
    sleep(rand(1..5))
    retry
  end

  def create_new_session
    session = ::Bunny.new
    session.start
    return session
  end

  def check_connection
    case @session

      when ::Bunny::Session
        @session.close if @session.status == :not_connected
        create_session if @session.closed?

      when NilClass
        create_session

    end
  rescue ::Bunny::TCPConnectionFailedForAllHosts
    sleep(1)
    retry
  end

  def create_session
    new_session = create_new_session
    new_session.logger.level = Logger::ERROR
    @session = new_session
  end

  def cluster
    Rack::App::Worker::Environment.worker_cluster
  end

  def namespace
    Rack::App::Worker::Environment.namespace
  end

  def create_channel
    new_channel = session.create_channel
    new_channel.basic_qos(Rack::App::Worker::Environment.queue_qos)
    new_channel
  end

  def exchange_cache
    @exchange_cache ||= {}
  end

  def exchange_for(type, name)
    exchange_cache[name] ||= proc {
      channel.fanout(exchange_name(type, name), :durable => true)
    }.call
  end

  def exchange_name(type, name)
    "#{namespace}.#{type}.#{name}"
  end

  def session_finalizer!
    @session_finalizer ||= lambda do
      this = self
      Kernel.at_exit do
        begin
          session = this.instance_variable_get(:@session)
          session && session.respond_to?(:close) && session.close
        rescue Timeout::Error
          nil
        end
      end
      true
    end.call
  end

end