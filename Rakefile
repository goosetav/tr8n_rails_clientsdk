#!/usr/bin/env rake
#begin
#  require 'bundler/setup'
#rescue LoadError
#  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
#end

begin
  require 'rdoc/task'
rescue LoadError
  require 'rdoc/rdoc'
  require 'rake/rdoctask'
  RDoc::Task = Rake::RDocTask
end

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Tr8n Client SDK for Ruby on Rails'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

#APP_RAKEFILE = File.expand_path("../test/dummy/Rakefile", __FILE__)
#load 'rails/tasks/engine.rake'
#
#Dir["#{File.dirname(__FILE__)}/lib/tasks/**/*.rake"].sort.each { |ext| load ext }
#
#Bundler::GemHelper.install_tasks
#
#require 'rake/testtask'
#
#Rake::TestTask.new(:test) do |t|
#  t.libs << 'lib'
#  t.libs << 'test'
#  t.pattern = 'test/**/*_test.rb'
#  t.verbose = false
#end

Dir["#{File.dirname(__FILE__)}/lib/tasks/**/*.rake"].sort.each { |ext| load ext }

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec
