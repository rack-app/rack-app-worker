require 'yaml'
# Bunny::Consumer
class Rack::App::Worker::Consumer

  def initialize(definition)
    @definition = definition
    @instance = @definition[:class].new
    @subscriptions = []
    @shutdown_requested = false
  end

  def start
    daemonizer.spawn do |d|
      d.process_title("Rack::App::Worker/#{@definition[:name]}/#{d.id}")
      start_working
    end
  end

  def stop
    daemonizer.send_signal('HUP', 1)
  end

  def stop_all
    daemonizer.send_signal('HUP')
  end

  protected

  def start_working
    logger.info "consumer start working for #{@definition[:name]}"
    rabbit = Rack::App::Worker::RabbitMQ.new
    subscribe(rabbit.send_queue(@definition[:name]))
    subscribe(rabbit.create_broadcast_queue(@definition[:name]))
    wait_for_shutdown
  end

  def wait_for_shutdown
    sleep(1) until @shutdown_requested
  end

  def handle_message(queue, delivery_info, properties, payload)
    method_name = properties[:headers]['method_name']
    args = YAML.load(payload)
    @instance.public_send(method_name, *args)
    queue.channel.ack(delivery_info.delivery_tag, false)
  rescue Exception
    queue.channel.nack(delivery_info.delivery_tag, false, true)
  end

  def at_shutdown
    logger.info 'cancel subscriptions'
    @subscriptions.each { |c| c.cancel }
    @shutdown_requested = true
  end

  def daemonizer
    @daemonizer ||= proc {
      daemonizer_instance = Rack::App::Worker::Daemonizer.new(@definition[:name])
      daemonizer_instance.on_shutdown { at_shutdown }
      daemonizer_instance.on_halt { at_shutdown }
      daemonizer_instance
    }.call
  end

  def subscribe(queue)
    logger.info "creating subscription for #{queue.name}"
    @subscriptions << queue.subscribe(:manual_ack => true) do |delivery_info, properties, payload|
      handle_message(queue, delivery_info, properties, payload)
    end
  end

  def logger
    @logger ||= Rack::App::Worker::Logger.new
  end

end