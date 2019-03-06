
lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "search_flip/version"

Gem::Specification.new do |spec|
  spec.name          = "search_flip"
  spec.version       = SearchFlip::VERSION
  spec.authors       = ["Benjamin Vetter"]
  spec.email         = ["vetter@flakks.com"]
  spec.description   = %q{Compositional EasticSearch client library}
  spec.summary       = %q{Powerful ElasticSearch client library to easily build complex queries}
  spec.homepage      = "https://github.com/mrkamel/search_flip"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.post_install_message = <<~MESSAGE
    Thanks for using search_flip!
    When upgrading from 1.x to 2.x, please check out
    https://github.com/mrkamel/search_flip/blob/master/UPDATING.md
  MESSAGE

  spec.add_development_dependency "activerecord", ">= 3.0"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "factory_bot"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "sqlite3", "~> 1.3.6"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "webmock"

  spec.add_dependency "hashie"
  spec.add_dependency "http"
  spec.add_dependency "oj"
end
