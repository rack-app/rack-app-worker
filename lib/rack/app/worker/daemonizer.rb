require 'timeout'
require 'securerandom'
class Rack::App::Worker::Daemonizer
  DEFAULT_KILL_SIGNAL = 'HUP'.freeze

  def initialize(daemon_name)
    @daemon_name = daemon_name.to_s
    @on_shutdown, @on_halt, @on_reload = proc {}, proc {}, proc {}
  end

  def id
    @id ||= SecureRandom.uuid
  end

  def spawn(&block)

    parent_pid = $$
    spawn_block = proc do
      subscribe_to_signals
      bind(parent_pid)
      save_current_process_pid
      redirect
      block.call(self)
    end

    try_fork(&spawn_block)

  end

  def daemonize
    case try_fork

      when NilClass #child
        subscribe_to_signals
        save_current_process_pid
        redirect

      else #parent
        Kernel.exit

    end
  end

  def process_title(new_title)
    if Process.respond_to?(:setproctitle)
      Process.setproctitle(new_title)
    else
      $0 = new_title
    end
  end

  def send_signal(signal, to_amount_of_worker=pids.length)
    pids.take(to_amount_of_worker).each do |pid|
      kill(signal, pid)
    end
  end

  def bind(to_pid)
    Thread.new do
      sleep(1) while Rack::App::Worker::Utils.process_alive?(to_pid)

      at_shutdown
    end
  end

  def on_shutdown(&block)
    raise('block not given!') unless block.is_a?(Proc)
    @on_shutdown = block
  end

  def on_halt(&block)
    raise('block not given!') unless block.is_a?(Proc)
    @on_halt = block
  end

  def on_reload(&block)
    raise('block not given!') unless block.is_a?(Proc)
    @on_reload = block
  end

  def subscribe_to_signals
    ::Signal.trap('INT'){ at_shutdown }
    ::Signal.trap('HUP'){ at_shutdown }
    ::Signal.trap('TERM'){ at_halt }
    ::Signal.trap('USR1'){ at_reload }
  end

  protected

  # Try and read the existing pid from the pid file and signal the
  # process. Returns true for a non blocking status.
  def kill(signal, pid)
    ::Process.kill(signal, pid)
    true
  rescue Errno::ESRCH
    $stdout.puts "The process #{pid} did not exist: Errno::ESRCH"
    true
  rescue Errno::EPERM
    $stderr.puts "Lack of privileges to manage the process #{pid}: Errno::EPERM"
    false
  rescue ::Exception => e
    $stderr.puts "While signaling the PID, unexpected #{e.class}: #{e}"
    false
  end

  def at_shutdown
    @on_shutdown.call
  ensure
    at_stop
  end

  def at_halt
    Timeout.timeout(10) { @on_halt.call } rescue nil
  ensure
    at_stop
  end

  def at_reload
    @on_reload.call
  end

  def at_stop
    File.write('/Users/aluzsi/Works/rack-app/worker/sandbox/out', pid_file_path)
    File.delete(pid_file_path) if File.exist?(pid_file_path)
    ::Kernel.exit
  end

  def try_fork(&block)
    pid = nil
    Timeout.timeout(15) { (Kernel.sleep(1) while (pid = ::Kernel.fork(&block)) == -1) }
    return pid
  rescue Timeout::Error
    raise('Fork failed!')
  end

  # Attempts to write the pid of the forked process to the pid file.
  def save_current_process_pid
    File.write(pid_file_path, $$)
  rescue ::Exception => e
    $stderr.puts "While writing the PID to file, unexpected #{e.class}: #{e}"
    Kernel.exit
  end

  def redirect
    Timeout.timeout(5) { try_redirect }
  rescue Timeout::Error
    raise('Cannot redirect standard io channels!')
  end

  # Send stdout and stderr to log files for the child process
  def try_redirect
    $stdin.reopen(Rack::App::Utils.devnull_path)
    $stdout.reopen(Rack::App::Worker::Environment.stdout)
    $stderr.reopen(Rack::App::Worker::Environment.stderr)
    $stdout.sync = $stderr.sync = true
  rescue Errno::ENOENT
    retry
  end

  def pids
    sorted_pid_files = Dir.glob(File.join(pids_folder_path, '*')).sort_by { |fp| File.mtime(fp) }
    sorted_pid_files.map { |file_path| File.read(file_path).to_i }
  end

  def pid_file_path
    File.join(pids_folder_path, id)
  end

  def pids_folder_path
    path = Rack::App::Utils.pwd('pids', 'workers', @daemon_name)
    FileUtils.mkdir_p(path)
    path
  end

end