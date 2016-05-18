rack-app-worker
===============

Rack::App::Worker is a Rack::App extension, that allow you to to create scalable asynchronous processing, that takes input in a non-blocking way.
With this you can create monstrous work-power for your project with a couple of line. 

The main two goal 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rack-app-worker'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rack-app-worker

## Usage

On the webs start the rack application as how you usualy do.
On the worker containers or server start with 
  $ rack-app workers start

or if you want run as a service in the background use the -d flag
  $ rack-app workers start -d 
  
to stop the daemonized process
  $ rack-app workers stop 
  
The workers use rabbitmq as message broker so you can easily scale horizontally the workers as how your pocket allow this.
By default the worker will scale vertically on the server as much as possible if the load requires.

You can configure the behavior with Linux variables:

```ruby

class App < Rack::App 

  apply_extensions :worker

  worker :payload_saver do

    def persist_payload(payload, hash_with_sym)
      Database[:some_table].inspert(value: payload)
    end

  end

  get '/' do
    workers[:payload_saver].send.persist_payload(payload, {:hello => params['hello']})
  end

end
 
```


## ENV Variables

### RABBITMQ_URL

this is required for connecting to rabbitmq 

### WORKER_QOS

this will manage how much message should be prefetched to a consumer. The default value is 50.

### WORKER_HEARTBEAT_INTERVAL

This variable manage the time delay between a new consumer creation or remove based on queue size demand

### WORKER_MAX_CONSUMER_NUMBER

This is used for limiting the maximum vertical of worker process count use

### WORKER_LOG_LEVEL

This is used to set the log output level for the extensions log messages

### WORKER_STDOUT

If this configurated, the background process will pipe all stdout io actions to the given output.

### WORKER_STDERR

Same as WORKER_STDOUT but for ERR

### WORKER_NAMESPACE

If you plan using multiple application on the same container/server than you should use worker namespace to add application specific uniq part to the queues.

### WORKER_CLUSTER

this is an optional env variable, this defines the workers cluster such as 'backup' or 'secondary'. 
This is useful when you have two seperated database and you want populate both at once,
but you only want one public web api which accept the incoming content.

