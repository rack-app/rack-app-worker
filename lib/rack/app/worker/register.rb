require 'rack/app/worker'
module Rack::App::Worker::Register

  require 'rack/app/worker/register/builder'
  require 'rack/app/worker/register/clients'

  extend self

  def add(name,class_constructor)
    builder = Rack::App::Worker::Register::Builder.new(name.to_sym)
    builder.consumer(class_constructor)
    worker_definitions[name.to_sym]= builder.to_def
    nil
  end

  def [](name)
    worker_definitions[name.to_sym]
  end

  def worker_definitions
    @worker_definitions ||= {}
  end

end