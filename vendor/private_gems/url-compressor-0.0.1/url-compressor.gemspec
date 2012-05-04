# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "url-compressor/version"

Gem::Specification.new do |s|
  s.name        = 'url-compressor'
  s.version     = UrlCompressor::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Anders Bengtsson"]
  s.email       = ["ndrsbngtssn@yahoo.se"]

  s.homepage    = ""
  s.summary     = %q{Compresses urls for use in other urls}
  s.description = %q{}

  s.files       = Dir.glob("lib/**/*") + %w(Gemfile Gemfile.lock url-compressor.gemspec)
  s.test_files  = Dir.glob('spec/**/*').reject! {|f| f =~ /\/SPEC\-/}

  s.add_development_dependency 'rspec-mocks', '~> 2.10'
  s.add_development_dependency 'rspec', '~> 2.10'
  s.add_development_dependency 'bundler', '~> 1.1.3'
end
