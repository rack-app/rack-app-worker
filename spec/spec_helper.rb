$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rack/app/worker'
require 'rack/app/test'

module TestFixtures
  extend(self)

  OUT_FILE_PATH = Rack::App::Utils.pwd('tmp','out.yml')

  def cleanup!
    File.delete(OUT_FILE_PATH) if File.exist?(OUT_FILE_PATH)
  end

  def out_file_content
    sleep(0.1) until File.exist?(OUT_FILE_PATH)

    return YAML.load(File.read(OUT_FILE_PATH))
  end

end