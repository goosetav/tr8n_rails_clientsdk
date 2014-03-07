source "http://rubygems.org"

# Declare your gem's dependencies in tr8n_client_sdk.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

#gem 'tr8n_core', :path => '../tr8n_ruby_core'

gem 'bundler'

gem 'puma'
gem 'unicorn'

gem 'dalli'
gem 'redis'

gem 'coveralls', require: false

group :development, :test do
  gem "rspec", "~> 2.14.1"
  gem "rspec-core", "~> 2.14.7"
  gem "rspec-mocks", "~> 2.14.4"
  gem 'rspec-rails'
  gem 'sqlite3'
  gem 'simplecov', '~> 0.7.1', :require => false
end

group :assets do
  gem 'sass-rails'
end