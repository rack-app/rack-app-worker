class Rack::App::Worker::Register::Builder

  def initialize(name)
    @name = name
  end

  def consumer(class_definition)
    if class_definition.is_a?(Class)
      @consumer_class = class_definition
    elsif class_definition.is_a?(Proc)
      klass = Class.new
      klass.class_exec(&class_definition)
      @consumer_class = klass
    end
  end

  def to_def
    {
        class: @consumer_class,
        name: @name,
        client: Rack::App::Worker::ClientProxy.new(@name)
    }
  end

end