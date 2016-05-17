require 'logger'
require 'rack/app/worker'
class Rack::App::Worker::Observer

  def initialize
    @shutdown_signal_received = false
    @ready_for_shutdown = false
  end

  def start
    logger.info(__method__.to_s)
    loop do
      break if shutdown_signal_received

      logger.debug(Rack::App::Worker::Register.worker_definitions.keys.inspect)
      Rack::App::Worker::Register.worker_definitions.values.each do |definition|

        queue = rabbitmq.send_queue(definition[:name])
        status = check_status(queue)

        if need_more_worker?(status)
          create_consumer(definition)
        end

        if need_less_worker?(status)
          signal_shutdown_for_a_consumer(definition)
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

  def create_consumer(definition)
    logger.info("#{__method__}(#{definition[:name]})")
    Rack::App::Worker::Consumer.new(definition).start
  end

  def signal_shutdown_for_a_consumer(definition)
    logger.info("#{__method__}(#{definition[:name]})")
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
      logger.info(__method__.to_s)
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

  def logger
    @logger ||= Rack::App::Worker::Logger.new
  end

end