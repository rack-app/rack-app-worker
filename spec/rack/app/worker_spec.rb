require 'spec_helper'

describe Rack::App::Worker do

  it 'has a version number' do
    expect(Rack::App::Worker::VERSION).to eq File.read(Rack::App::Utils.pwd('VERSION')).strip
  end

  include Rack::App::Test

  rack_app do

    apply_extensions :worker

    worker :payload_saver do

      def persist_payload(payload, hash_with_sym)
        puts 'event received'
        File.write(hash_with_sym[:file_path], YAML.dump([payload, hash_with_sym]))
      end

    end

    worker :sleepy do

      def some_heavy_lifting_that_takes_time
        Kernel.sleep(5)
      end

    end

    get '/' do
      workers[:payload_saver].send.persist_payload(payload, {:file_path => params['file_path']})
    end

    get '/sleepy' do
      workers[:sleepy].send.some_heavy_lifting_that_takes_time
    end

  end

  before { TestFixtures.cleanup! }

  it 'should process the request from the api do the daemons' do

    payload_content = 'Hello, World!'

    file_path = File.join(TestFixtures::TMP_FOLDER_PATH, Rack::App::Utils.uuid)

    get('/', params: {"file_path" => file_path}, payload: payload_content)

    content = TestFixtures.out_file_content(file_path)
    expect(content).to be_a Array
    expect(content[0]).to eq payload_content
    expect(content[1]).to eq :file_path => file_path

  end

  it 'should create pid folder for each type of worker' do
    purge_pid_files

    expect(worker_pid_folders.map { |fp| File.basename(fp) }).to match_array(%W[payload_saver master sleepy])
  end

  it 'each process id file should point to a existing process' do
    purge_pid_files

    worker_pid_folders.each do |pid_folder|
      Dir.glob(File.join(pid_folder, '*')).each do |pid_file_path|
        Process.kill(0, File.read(pid_file_path).to_i)
      end
    end

  end

  it 'should increase the worker count to match the request load' do
    purge_pid_files

    expected_worker_count = Rack::App::Worker::Environment.max_consumer_number

    request_count = Rack::App::Worker::Environment.message_count_limit * Rack::App::Worker::Environment.queue_qos * (expected_worker_count + 5)
    request_count.times { get('/sleepy') }

    sleepy_worker_consumer_pid_folder = worker_pid_folders.select { |fp| File.basename(fp) == 'sleepy' }

    timeout(60) { sleep(1) until Dir.glob(File.join(sleepy_worker_consumer_pid_folder, '*')).length == expected_worker_count }


    Dir.glob(File.join(sleepy_worker_consumer_pid_folder, '*')).each do |fp|
      Process.kill(0, File.read(fp).to_i)
    end

  end

end