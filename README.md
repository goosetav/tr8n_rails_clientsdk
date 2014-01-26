<p align="center">
  <img src="https://raw.github.com/tr8n/tr8n/master/doc/screenshots/tr8nlogo.png">
</p>

Tr8n Client SDK for Ruby on Rails
===================================

This Client SDK provides tools and extensions necessary for translating any Rails application using the Tr8n service.

[![Build Status](https://travis-ci.org/tr8n/tr8n_rails_clientsdk.png?branch=master)](https://travis-ci.org/tr8n/tr8n_rails_clientsdk)
[![Dependency Status](https://www.versioneye.com/user/projects/52e4bc4cec1375b57600000f/badge.png)](https://www.versioneye.com/user/projects/52e4bc4cec1375b57600000f)


Runing the Client SDK Sample
===================================


To run the gem as a stand-alone application follow these:

Make sure you edit the config/tr8n/config.yml file and provide the correct application host, key and secret for your application.

```sh
  $ git clone https://github.com/tr8n/tr8n_rails_clientsdk.git
  $ cd tr8n_rails_clientsdk/test/dummy
  $ bundle install
  $ rake db:migrate
  $ rails s -p 3001
```

Alternatively, you can see the same sample application as a stand alone app:

https://github.com/tr8n/tr8n_rails_clientsdk_sample


# Integration Instructions

Here are a few points on how to integrate Tr8n into your app:

Add the following gems to your Gemfile:

```ruby
  gem 'tr8n_core'
  gem 'tr8n_client_sdk'
```

Install the gems:

```sh
  $ bundle
```

Generate config file:

```sh
  $ rails g tr8n_client_sdk
```

Open the config file and provide your application credentials:

```
  application:
    host:         http://localhost:3000
    key:          YOUR_APP_KEY
    secret:       YOUR_APP_SECRET
```

In the HEAD section of your layout, add:

```ruby
  <%= tr8n_scripts_tag %>
```

You are done, tr8n is now running in your app.

To read more about what you can do with it, visit the wiki site:

http://wiki.tr8nhub.com
