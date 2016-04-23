module Rack::App::Worker::Utils

  extend(self)

  def process_alive?(pid)
    ::Process.kill(0, pid.to_i)
    return true
  rescue ::Errno::ESRCH
    return false
  end

  def maximum_allowed_process_number
    (`ulimit -u`.to_i * 0.75).to_i + 10
  rescue Errno::ENOENT
    100
  end

end