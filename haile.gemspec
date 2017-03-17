# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'haile/version'

Gem::Specification.new do |spec|
  spec.name          = "haile"
  spec.version       = Haile::VERSION
  spec.authors       = ["Tobi Knaup", "Chris Kite"]
  spec.description   = %q{Ruby client for Marathon REST API}
  spec.summary       = %q{Ruby client for Marathon REST API}
  spec.homepage      = "https://github.com/chriskite/haile"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "trollop", "~> 2.0"
  spec.add_dependency "httparty", "~> 0.11"
  spec.add_dependency "multi_json", "~> 1.8"
  spec.add_dependency 'colorize', '~> 0.7.7', '>= 0.7.7'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 0"
end
