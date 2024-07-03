source "https://rubygems.org"

gemspec

if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.2.2")
  gem "activerecord", ">= 3.0", "< 5"
else
  gem "activerecord", ">= 3.0"
end

gem "aws-sdk-core"
gem "bundler"
gem "factory_bot"
gem "rake"
gem "rspec"
gem "rubocop"
gem "sqlite3", "~> 1.4"
gem "timecop"
gem "webmock"
