# Tr8n Client SDK for Ruby on Rails

This Client SDK provides all tools and extensions necessary for translating any Rails application using the Tr8n service.

The service must be available and running in order for the SDK to work. You can download and install the service by following these instructions:

```sh
  $ git clone https://github.com/tr8n/tr8n.git
  $ cd tr8n/test/dummy
  $ bundle install
  $ rake db:migrate
  $ rake tr8n:init
  $ rails s
```

Open your browser and point to:

  http://localhost:3000

This is your Tr8n Service Instance.

Now you can install and run the Client SDK sample.


# Runing the Client SDK Sample

To run the gem as a stand-alone application follow these:

Make sure you edit the config/tr8n/config.yml file and provide the correct application host, key and secret for your application.

```sh
  $ git clone https://github.com/tr8n/tr8n_rails_clientsdk.git
  $ cd tr8n_rails_clientsdk/test/dummy
  $ bundle install
  $ rake db:migrate
  $ rails s -p 3001
```


Open your browser and point to:

  http://localhost:3001
