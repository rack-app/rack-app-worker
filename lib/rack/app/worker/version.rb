require 'rack/app/worker'
Rack::App::Worker::VERSION = File.read(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'VERSION')).strip