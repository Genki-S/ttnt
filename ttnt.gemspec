# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ttnt/version'

Gem::Specification.new do |spec|
  spec.name          = "ttnt"
  spec.version       = TTNT::VERSION
  spec.authors       = ["Genki Sugimoto"]
  spec.email         = ["cfhoyuk.reccos.nelg@gmail.com"]

  spec.summary       = %q{Select test cases to run based on changes in committed code}
  # spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = "http://github.com/Genki-S/ttnt"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rugged", "0.23.0b2"
  spec.add_dependency "json", "1.8.3"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"

  # Pry
  spec.add_development_dependency "hirb"
  spec.add_development_dependency "awesome_print"
  spec.add_development_dependency "pry"
end
