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
        File.write(TestFixtures::OUT_FILE_PATH, YAML.dump([payload, hash_with_sym]))
      end

    end

    get '/' do
      workers[:payload_saver].send.persist_payload(payload, {:hello => params['hello']})
    end

  end

  before { TestFixtures.cleanup! }

  # let(:observer_thread) { Thread.new { Rack::App::Worker::CLI.start({}) } }
  # before { observer_thread }
  # after { observer_thread.terminate }
  #
  # it 'should process the request from the api do the daemons' do
  #
  #   param_hello_content = 'world'
  #   payload_content = 'Hello, World!'
  #
  #   get('/', params: {"hello" => param_hello_content}, payload: payload_content)
  #
  #   content = TestFixtures.out_file_content
  #
  #   expect(content[0]).to eq payload_content
  #   expect(content[1]).to eq(:hello => param_hello_content)
  #
  # end

end