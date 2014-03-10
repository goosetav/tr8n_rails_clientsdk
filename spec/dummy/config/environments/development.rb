Dummy::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  Tr8n.configure do |config|
    config.application = {
        :host => "https://sandbox.tr8nhub.com",
        :key => "577fdeb280372b87c",
        :secret => "77a71ca7e10434777"
    }
    #config.application = {
    #    :host => "http://localhost:3000",
    #    :key => "6b714be8673fcc4a3",
    #    :secret => "5c873790ebdc7d7b8"
    #}
    config.cache = {
        :enabled  => true,
        :adapter  => 'memcache',
        :host     => 'localhost:11211',
        :version  => 1,
        :timeout  => 3600
    }
    config.logger  = {
        :enabled  => false,
        :path     => "#{Rails.root}/log/tr8n.log",
        :level    => 'debug'
    }
  end


end
