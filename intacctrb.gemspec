# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'intacctrb/version'

Gem::Specification.new do |spec|
  spec.name          = "intacctrb"
  spec.version       = IntacctRB::VERSION
  spec.authors       = ["Matt Hale"]
  spec.email         = ["matt.hale.0@gmail.com"]
  spec.description   = %q{Ruby lib to communicate with the Intacct API system. Forked from https://github.com/cj/intacct.}
  spec.summary       = %q{Ruby Intacct API Client}
  spec.homepage      = "https://github.com/apexdp/intacctrb"
  # spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri"
  spec.add_dependency "hooks"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "turnip"
  spec.add_development_dependency "awesome_print"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "dotenv-rails"
  spec.add_development_dependency "faker", ">=1.2.0"
end
