# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'elastic_search/version'

Gem::Specification.new do |spec|
  spec.name          = "elastic_search"
  spec.version       = ElasticSearch::VERSION
  spec.authors       = ["Benjamin Vetter"]
  spec.email         = ["vetter@flakks.com"]
  spec.description   = %q{Compositional ElasticSearch client library}
  spec.summary       = %q{Powerful ElasticSearch client library to easily build complex queries}
  spec.homepage      = "https://github.com/mrkamel/elastic_search"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_dependency "rest-client"
  spec.add_dependency "hashie"
end

