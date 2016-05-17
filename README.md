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

### WORKER_CLUSTER

this is an optional env variable, this defines the workers cluster such as 'backup' or 'secondary'. 
This is useful when you have two seperated database and you want populate both at once,
but you only want one public web api which accept the incoming content.

