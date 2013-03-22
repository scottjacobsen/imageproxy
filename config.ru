require 'rubygems'
require 'bundler'
Bundler.require :default

require File.join(File.expand_path(File.dirname(__FILE__)), "lib", "imageproxy")

run Rack::Sendfile.new(Imageproxy::Server.new)