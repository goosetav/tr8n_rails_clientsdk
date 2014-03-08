<p align="center">
  <img src="https://raw.github.com/tr8n/tr8n/master/doc/screenshots/tr8nlogo.png">
</p>

Tr8n Client SDK for Ruby on Rails
===================================

This Client SDK provides tools and extensions necessary for translating any Rails application using the Tr8n service.

[![Build Status](https://travis-ci.org/tr8n/tr8n_rails_clientsdk.png?branch=master)](https://travis-ci.org/tr8n/tr8n_rails_clientsdk)
[![Coverage Status](https://coveralls.io/repos/tr8n/tr8n_rails_clientsdk/badge.png)](https://coveralls.io/r/tr8n/tr8n_rails_clientsdk)
[![Gem Version](https://badge.fury.io/rb/tr8n_client_sdk.png)](http://badge.fury.io/rb/tr8n_client_sdk)
[![Dependency Status](https://www.versioneye.com/user/projects/52e4bc4cec1375b57600000f/badge.png)](https://www.versioneye.com/user/projects/52e4bc4cec1375b57600000f)
[![Project status](http://stillmaintained.com/tr8n/tr8n_ruby_core.png)](http://stillmaintained.com/tr8n/tr8n_ruby_core.png)


Runing the Client SDK Sample
===================================


To run the gem as a stand-alone application follow these:

Make sure you edit the config/tr8n/config.yml file and provide the correct application host, key and secret for your application.

```sh
  $ git clone https://github.com/tr8n/tr8n_rails_clientsdk.git
  $ cd tr8n_rails_clientsdk/spec/dummy
  $ bundle
  $ script/rails s
```

Alternatively, you can see the same sample application as a stand alone app:

https://github.com/tr8n/tr8n_rails_clientsdk_sample

This application is running at:

http://rails.tr8nhub.com



Integration Instructions
===================================

To integrate Tr8n into your app, all you need to do is:

Add the following gems to your Gemfile:

```ruby
  gem 'tr8n_client_sdk'
```

Install the gems:

```sh
  $ bundle
```

Add the following configuration to your Application.rb:

```ruby
    Tr8n.configure do |config|
      config.application = {
          :key => YOUR_APP_KEY,
          :secret => YOUR_APP_SECRET
      }
    end
```

In the HEAD section of your layout, add:

```ruby
  <%= tr8n_scripts_tag %>
```

You are done, tr8n is now running in your app.


Now you can simply add the default language selector anywhere on your page using:

```ruby
  <%= tr8n_language_selector_tag %>
```

And use TML (Translation Markup Language) to translate your strings, using:

```ruby
  <%= tr("Hello World") %>
  <%= tr("You have {count||message}", :count => 5) %>
  <%= tr("{actor} sent {target} [bold: {count||gift}]", :actor => actor_user, :target => target_user, :count => 5) %>
  ...
```

Learn more about TML at: http://wiki.tr8nhub.com


Caching
===================================

You should enable caching for your application. Without caching you will be querying the service for new translations on every page load.
If you do it too much, you will be throttled. The translation service is designed to service the up-to-date translations only if you your translators are in translation mode.
For all other users you should serve translations from your cache.

To enable cache, simply add the following configuration to Tr8n config:

```ruby
    Tr8n.configure do |config|
      config.cache = {
          :enabled  => true,
          :adapter  => 'memcache',
          :host     => 'localhost:11211',
          :version  => 2,
          :timeout  => 3600
      }
    end
```

The following Cache adapters are supported:

Memcache, Redis, CDB, File

It is easy to add any other custom cache adapter as well.

Memcache and Redis adapters can do a realtime cache warmup - by loading the translations from the service and storing them in the cache.

To reset/upgrade your cache, you can simply call

```ruby
  Tr8n.cache.upgrade_version
```

All the keys stored in memory based cache are versioned. By upgrading the version you will effectively invalidate the old keys and the new keys will be loaded from the translation service.


CDB and File adapters require pre-generation. You can pre-generate your cache by running:

```sh
  $ rake tr8n:generate_cache:file
```

or

```sh
  $ rake tr8n:generate_cache:cdb
```

You can also do a combination of file-based adapters (for persistent cache) and memory-based adapters for serving the translations.


Logging
===================================

Tr8n comes with its own logger. If you would like to see what the SDK is doing behind the scene, enable the logger and provide the file path for the log file:

```ruby
    Tr8n.configure do |config|

      config.logger  = {
          :enabled  => true,
          :path     => "#{Rails.root}/log/tr8n.log",
          :level    => 'debug'
      }

    end
```


Rules Engine Customizations
===================================

Tr8n comes with default settings for the rules engine. For example, it assumes that you have the following methods in your ApplicationController:

```ruby
  def current_user
  end

  def current_locale
  end
```

Tr8n only needs the current_user method if your site needs to use gender based rules for the viewing user.

Similarly, if you prefer to use your own mechanism for storing and retrieving user's preferred and selected locales, you can provide the current_locale method.

If you need to adjust those method names, you can set them in the config:

```ruby
    Tr8n.configure do |config|

      config.current_user_method = :my_user

      config.current_locale_method = :my_locale

    end
```




To read more about what you can do with Tr8n, visit the wiki site:

http://wiki.tr8nhub.com
