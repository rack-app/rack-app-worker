module Rack::App::Worker::DSL::ForClass

  def worker(name, &block)
    Rack::App::Worker::Register.add(name,block) unless block.nil?
  end
  alias define_worker worker

  def workers
    Rack::App::Worker::Register
  end

end