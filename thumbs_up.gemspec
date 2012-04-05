# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'thumbs_up/version'

Gem::Specification.new do |s|
  s.name = "thumbs_up"
  s.version = ThumbsUp::VERSION

  s.required_rubygems_version = '>= 1.6.0'
  s.homepage = "http://github.com/brady8/thumbs_up"
  s.summary = "Voting for ActiveRecord with multiple vote sources and karma calculation."
  s.description = "ThumbsUp provides dead-simple voting capabilities to ActiveRecord models with karma calculation, a la stackoverflow.com."
  s.authors = ["Brady Bouchard", "Peter Jackson", "Cosmin Radoi", "Bence Nagy", "Rob Maddox", "Wojciech Wnetrzak"]
  s.email = ["brady@thewellinspired.com"]
  s.files = Dir.glob("{lib,rails,test}/**/*") + %w(CHANGELOG.md Gemfile MIT-LICENSE README.md Rakefile)
  s.require_paths = ["lib"]

  s.add_runtime_dependency('activerecord')
  s.add_runtime_dependency('statistics2')
  s.add_development_dependency('simplecov')
  s.add_development_dependency('bundler')
  s.add_development_dependency('mysql2')
  s.add_development_dependency('rake')

end

