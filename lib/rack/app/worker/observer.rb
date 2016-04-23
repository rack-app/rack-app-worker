require 'rack/app/worker'
class Rack::App::Worker::Observer

  def initialize
    @shutdown_signal_received = false
    @ready_for_shutdown = false
  end

  def start
    loop do
      break if shutdown_signal_received

      Rack::App::Worker::Register.worker_definitions.values.each do |definition|

        queue = rabbitmq.send_queue(definition[:name])
        status = check_status(queue)

        if need_more_worker?(status)
          create_child(definition)
        end

        if need_less_worker?(status)
          signal_shutdown_for_a_child(definition)
        end

      end

      sleep(heartbeat_interval)

    end
  end

  def stop
    @shutdown_signal_received = true
    sleep(0.1) until @ready_for_shutdown
  end

  protected

  def check_status(queue)
    queue.status
  rescue Timeout::Error
    retry
  end

  def create_child(definition)
    Rack::App::Worker::Consumer.new(definition).start
  end

  def signal_shutdown_for_a_child(definition)
    Rack::App::Worker::Consumer.new(definition).stop
  end

  def heartbeat_interval
    Rack::App::Worker::Environment.heartbeat_interval
  end

  def message_count_limit
    Rack::App::Worker::Environment.message_count_limit
  end

  def shutdown_signal_received
    if @shutdown_signal_received
      consumers.each { |c| c.stop_all }
      rabbitmq.session.close
      @ready_for_shutdown = true
    end
    (!!@ready_for_shutdown)
  end

  def need_less_worker?(status)
    (status[:message_count] < message_count_limit) and (status[:consumer_count] > 1)
  end

  def need_more_worker?(status)
    ((status[:consumer_count] == 0) or (status[:message_count] >= message_count_limit)) and
        status[:consumer_count] <= Rack::App::Worker::Environment.max_consumer_number
  end

  def consumers
    Rack::App::Worker::Register.worker_definitions.values.map do |definition|
      Rack::App::Worker::Consumer.new(definition)
    end
  end

  def rabbitmq
    @rabbitmq ||= Rack::App::Worker::RabbitMQ.new
  end

end