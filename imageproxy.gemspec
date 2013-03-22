lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'imageproxy/version'

Gem::Specification.new do |gem|
  gem.name = "imageproxy"
  gem.version = Imageproxy::Version

  gem.author        = "Erik Hanson"
  gem.description   = "An image processing proxy server, written in Ruby as a Rack application. Requires ImageMagick."
  gem.summary       = "A image processing proxy server, written in Ruby as a Rack application."
  gem.email         = "erik@eahanson.com"
  gem.homepage      = "http://github.com/eahanson/imageproxy"

  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep %r{^(test|spec|features)/}
  gem.license       = "MIT"
  gem.require_paths = ["lib"]

  gem.add_dependency "rest-client", "~> 1.6.7"
  gem.add_dependency "mime-types"
  gem.add_dependency "rmagick", "~> 2.13.2"
  gem.add_dependency "newrelic_rpm"
end
