require 'rack/app/worker'
module Rack::App::Worker::Environment
  extend(self)

  DEFAULT_QOS = 50
  DEFAULT_WORKER_CLUSTER = 'main'.freeze
  DEFAULT_WORKER_NAMESPACE = 'rack-app-worker'.freeze
  DEFAULT_HEARTBEAT_INTERVAL = 10
  DEFAULT_MESSAGE_COUNT_LIMIT = 50
  DEFAULT_MAX_CONSUMER_NUMBER = Rack::App::Worker::Utils.maximum_allowed_process_number

  def worker_cluster
    (ENV['WORKER_CLUSTER'] || DEFAULT_WORKER_CLUSTER).to_s
  end

  def queue_qos
    (ENV['WORKER_QOS'] || DEFAULT_QOS).to_i
  end

  def namespace
    (ENV['WORKER_NAMESPACE'] || DEFAULT_WORKER_NAMESPACE).to_s
  end

  def heartbeat_interval
    (ENV['WORKER_HEARTBEAT_INTERVAL'] || DEFAULT_HEARTBEAT_INTERVAL).to_i
  end

  def message_count_limit
    (ENV['WORKER_MESSAGE_COUNT_LIMIT'] || DEFAULT_MESSAGE_COUNT_LIMIT).to_i
  end

  def max_consumer_number
    (ENV['WORKER_MAX_CONSUMER_NUMBER'] || DEFAULT_MAX_CONSUMER_NUMBER).to_i
  end

  def log_level
    case ENV['WORKER_LOG_LEVEL'].to_s.upcase

      when 'DEBUG', '0'
        0

      when 'INFO', '1'
        1

      when 'WARN', '2'
        2

      when 'ERROR', '3'
        3

      when 'FATAL', '4'
        4

      when 'UNKNOWN', '5'
        5

      else
        3

    end
  end

  def stdout
    (ENV['WORKER_STDOUT'] || Rack::App::Utils.devnull_path).to_s
  end

  def stderr
    (ENV['WORKER_STDERR'] || Rack::App::Utils.devnull_path).to_s
  end

end