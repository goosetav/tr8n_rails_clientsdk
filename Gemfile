source "http://rubygems.org"

# Declare your gem's dependencies in tr8n_client_sdk.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

#gem 'tr8n_core', :path => '../tr8n_ruby_core'

gem 'tr8n_core', '1.1.3'

gem 'bundler'

gem 'puma'
gem 'unicorn'

gem 'dalli'
gem 'redis'

group :development, :test do
  gem "rspec", "~> 2.14.1"
  gem "rspec-core", "~> 2.14.7"
  gem "rspec-mocks", "~> 2.14.4"
  gem 'rspec-rails'
  gem 'sqlite3'
end

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier',     '>= 1.0.3'
end