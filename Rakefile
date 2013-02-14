# encoding: UTF-8
require 'rubygems'
require 'bundler' unless defined?(Bundler)

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'thumbs_up/version'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.test_files = Dir.glob("test/**/*_test.rb")
  test.verbose = true
end

task :build do
  system "gem build thumbs_up.gemspec"
end

task :release => :build do
  system "gem push thumbs_up-#{ThumbsUp::VERSION}.gem"
  system "rm thumbs_up-#{ThumbsUp::VERSION}.gem"
end

task :test_all_databases do
  # Test MySQL, Postgres and SQLite3
  ENV['DB'] = 'mysql'
  Rake::Task['test'].execute
  ENV['DB'] = 'postgres'
  Rake::Task['test'].execute
  ENV['DB'] = 'sqlite3'
  Rake::Task['test'].execute
end

task :default => :test_all_databases
