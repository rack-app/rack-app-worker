$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rack/app/worker'
require 'rack/app/test'
require 'timeout'

module TestFixtures

  extend(self)

  TMP_FOLDER_PATH = Rack::App::Utils.pwd('tmp')

  def cleanup!

    FileUtils.mkpath(TMP_FOLDER_PATH)

    Dir.glob(File.join(TMP_FOLDER_PATH, '*')).each do |fp|
      File.delete(fp) unless File.directory?(fp)
    end

  end

  def out_file_content(file_path)
    timeout(20) { sleep(0.1) until File.exist?(file_path) } rescue nil

    content = YAML.load(File.read(file_path))
    content
  end

end

module WorkerControl

  def purge_pid_files
    Dir.glob(Rack::App::Utils.pwd('pids', 'workers', '*')).each do |folder|
      if Dir.glob(File.join(folder, '*')).empty?
        FileUtils.rm_r(folder)
      end
    end
  end

  def start_daemon

    Kernel.fork do
      Rack::App::Worker::CLI.start({:daemonize => true})
    end

    daemonizer = Rack::App::Worker::Daemonizer.new('master')
    sleep(0.1) until daemonizer.has_running_process?

  end

  def stop_daemon
    Rack::App::Worker::CLI.stop({})
    daemonizer = Rack::App::Worker::Daemonizer.new('master')
    sleep(0.1) while daemonizer.has_running_process?
  end

  def worker_pid_folders
    Dir.glob(Rack::App::Utils.pwd('pids', 'workers', '*')).select { |fp| File.directory?(fp) }
  end

  def try_wait_for_workers
    worker_count_with_master_included = worker_definitions.length + 1
    timeout(30) { sleep(1) until worker_pid_folders.length == worker_count_with_master_included } rescue nil
  end

  def worker_definitions
    rack_app.workers.worker_definitions
  end

end

RSpec.configuration.include(WorkerControl)

RSpec.configuration.before(:each) do
  rack_app
  start_daemon
  try_wait_for_workers

  rabbit = Rack::App::Worker::RabbitMQ.new
  worker_definitions.keys.each do |name|
    queue = rabbit.send_queue(name)
    queue.purge
  end

end

RSpec.configuration.after(:each) do
  stop_daemon
end

Kernel.at_exit do
  Rack::App::Worker::Daemonizer.new('master').send_signal('TERM')
end

ENV['WORKER_STDOUT']= Rack::App::Utils.pwd('tmp', 'spec.log')
ENV['WORKER_STDERR']= Rack::App::Utils.pwd('tmp', 'spec.log')
ENV['WORKER_LOG_LEVEL']= '0'
ENV['WORKER_QOS']= '1'