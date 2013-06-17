$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "tr8n_client_sdk/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "tr8n_client_sdk"
  s.version     = Tr8nClientSdk::VERSION
  s.authors     = ["Michael Berkovich"]
  s.email       = ["theiceberk@gmail.com"]
  s.homepage    = "http://www.tr8nhub.com"
  s.summary     = "Tr8n Client SDK for Ruby"
  s.description = "Client SDK for Tr8n translation engine."

  s.files = Dir["{app,config,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency 'rails',     '~> 3.2.13'
  s.add_dependency 'sass',      '>= 0'
  s.add_dependency 'thor',      '>= 0'
  s.add_dependency 'faraday',   '>= 0'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'dalli'
  s.add_development_dependency 'bundler',     '>= 1.0.0'
  s.add_development_dependency 'rr'
  s.add_development_dependency 'bcrypt-ruby'
end
