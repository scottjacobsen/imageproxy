#encoding:utf-8
require 'url-compressor/version'

require 'base64'
require 'zlib'

module UrlCompressor

  DICTIONARY = [
          "http://", "https://", "tv4.se", "www",
          "polopoly_fs", "img", "annotagger", "-stage", "heroku", "api",
          "tv4play", "sth.basefarm.net", "wordpress-mu", "cdn01",
          "grid", "site", "original", "image",
          ".com", ".org",
          ".jpg", ".gif", ".png"
  ].join.freeze
  VERSION_BYTE = "\0".freeze

  def self.compress(url)
    deflated = deflate(url.encode("UTF-8"))
    Base64.urlsafe_encode64("#{VERSION_BYTE}#{deflated}")
  end

  def self.decompress(compressed)
    decoded = Base64.urlsafe_decode64(compressed)
    inflate(decoded[VERSION_BYTE.bytesize..-1]).force_encoding("UTF-8")
  end

  private

  WINDOW_BITS = -15 # Negative for raw (without headers) output

  def self.deflate(s)
    z = Zlib::Deflate.new(Zlib::BEST_COMPRESSION, WINDOW_BITS)
    z.set_dictionary(DICTIONARY)
    result = z.deflate(s, Zlib::FINISH)
    z.close
    result
  end

  def self.inflate(s)
    z = Zlib::Inflate.new(WINDOW_BITS)
    z.set_dictionary(DICTIONARY)
    result = z.inflate(s)
    z.finish
    z.close
    result
  end
end
