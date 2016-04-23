# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "rack-app-worker"
  spec.version       = File.read(File.join(File.dirname(__FILE__),'VERSION')).strip
  spec.authors       = ["Adam Luzsi"]
  spec.email         = ["adamluzsi@gmail.com"]

  spec.summary       = %q{Rack::App framework background worker extension}
  spec.description   = %q{Rack::App framework background worker extension}

  spec.homepage      = "http://www.rack-app.com"
  spec.license       = 'Apache License Version 2.0'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.required_ruby_version = Gem::Requirement.new(">= 2.0")

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_dependency "rack-app", ">= 3.6.0"
  spec.add_dependency "bunny", ">= 2.3.0"

end
