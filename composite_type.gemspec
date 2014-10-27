# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'composite_type/version'

Gem::Specification.new do |spec|
  spec.name          = "composite_type"
  spec.version       = CompositeType::VERSION
  spec.authors       = ["Kurt Stephens"]
  spec.email         = ["ks.github@kurtstephens.com"]
  spec.description   = %q{Composite Types for Ruby}
  spec.summary       = %q{Array.of(String)}
  spec.homepage      = "https://github.com/kstephens/composite_type"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov", "~> 0.8"
  spec.add_development_dependency "pry", "~> 0.9"
  spec.add_development_dependency "guard", "~> 2.6"
  spec.add_development_dependency "guard-rspec", "~> 4.3"
end
