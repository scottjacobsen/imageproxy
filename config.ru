require 'bundler'
require 'rack/sendfile'
require 'aws/s3'
require 'dalli'
require 'digest/md5'

require File.dirname(__FILE__) + "/imageproxy"

#run Rack::Cascade.new([Rack::Sendfile.new(Server.new), Server.new])
run Rack::Sendfile.new(Server.new)
#run Server.new