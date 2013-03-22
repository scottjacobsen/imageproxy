unless ENV["RACK_ENV"] == "stage" || ENV["RACK_ENV"] == "production"
require 'bundler/gem_tasks'
begin
  require 'ci/reporter/rake/rspec'     # use this if you're using RSpec
rescue LoadError
  puts "could not load ci_reporter rspec task"
end

Bundler.require :test

desc "Run all specs"
task :spec do
  system 'rspec --format nested --color spec'
end

task :default => :spec

desc "Run the server locally (for development)"
task :run do
  require 'uri'
  puts <<EOF

See examples at:

  http://localhost:9393/selftest

If you set IMAGEPROXY_SIGNATURE_REQUIRED and IMAGEPROXY_SIGNATURE_SECRET
environment variables, then the requests in the selftest will be
signed.

EOF
  system 'shotgun'
end


require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "imageproxy"
  gem.homepage = "http://github.com/eahanson/imageproxy"
  gem.license = "MIT"
  gem.summary = %Q{A image processing proxy server, written in Ruby as a Rack application.}
  gem.description = %Q{A image processing proxy server, written in Ruby as a Rack application. Requires ImageMagick.}
  gem.email = "erik@eahanson.com"
  gem.authors = ["Erik Hanson"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

end
require 'heroku-api'

namespace :scale do
  desc "Scale dynos to extrasmall mode"
  task :extrasmall do
  scale_dynos(3)
  end

  desc "Scale dynos to small mode"
  task :small do
  scale_dynos(15)
  end

  desc "Scale dynos to medium mode"
  task :medium do
  scale_dynos(25)
  end

  desc "Scale dynos to extralarge mode"
  task :large do
  scale_dynos(35)
  end

  desc "Scale dynos to extralarge mode"
  task :extralarge do
  scale_dynos(50)
  end

  desc "Scale dynos to panic mode"
  task :panic do
  scale_dynos(80)
  end

  def scale_dynos(dynos)
  heroku = Heroku::API.new(:api_key => ENV['MY_API_KEY'])
  heroku.post_ps_scale(ENV['APP_NAME'], 'web', dynos)
  end
end
