$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "tr8n_client_sdk/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "tr8n_client_sdk"
  s.version     = Tr8nClientSdk::VERSION
  s.authors     = ["Michael Berkovich"]
  s.email       = ["michael@tr8nhub.com"]
  s.homepage    = "https://github.com/tr8n/tr8n_rails_clientsdk"
  s.summary     = "Tr8n Client SDK for Ruby on Rails"
  s.description = "Client SDK for Tr8n translation engine."

  s.files = Dir["{app,config,lib}/**/*"] + ["LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]
  s.licenses = "MIT-LICENSE"

  s.add_dependency 'rails', '~> 4.0.0'
  s.add_dependency 'tr8n_core', '~> 4.0.4'
end
