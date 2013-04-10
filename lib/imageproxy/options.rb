require 'uri'
require 'cgi'
require 'mime/types'

module Imageproxy
  class Options
    def initialize(path, query_params)
      params_from_path = path.split('/').reject { |s| s.nil? || s.empty? }
      command = params_from_path.shift

      @hash = Hash[*params_from_path]
      @hash['command'] = command
      @hash.merge! query_params
      merge_obfuscated
      @hash["source"] = @hash.delete("src") if @hash.has_key?("src")

      unescape_source
      remap_source
      unescape_signature
      check_parameters
    end

    def check_parameters
      check_param('resize', /^(\d{1,5}(x\d{1,5})?)|(x\d{1,5})$/) # XxY, X, Xx or xY
      check_param('thumbnail', /^\d{1,5}(x\d{1,5})?$/)
      check_param('rotate', /^(-)?\d{1,3}(\.\d+)?$/)
      check_param('format', /^[0-9a-zA-Z]{2,6}$/)
      check_param('progressive', /^true|false$/i)
      check_param('background', /^#[0-9a-f]{3}([0-9a-f]{3})?|rgba\(\d{1,3},\d{1,3},\d{1,3},[0-1](.\d+)?\)$/)
      check_param('shape', /^preserve|pad|cut$/i)
      check_param('aspect_ratio', /^\d{1,3}\:\d{1,3}$/)
      @hash['quality'] = [[@hash['quality'].to_i, 100].min, 0].max.to_s if @hash.has_key?('quality')
    end

    def check_param(param, rega)
      if @hash.has_key? param
        if (!rega.match(@hash[param]))
          @hash.delete(param)
        end
      end
    end

    def remap_source
      return unless ENV['toggle.remap_prima'] == 'true'
      return unless @hash.has_key? 'source'
      # Since Prima is slow, we'll fetch those images via API4's proxy, which is Akamai cached.
      @hash['source'] = @hash['source'].sub(%r{^http://prima\.tv4play\.se/}, 'http://webapi.tv4play.se/prima/')
      # For some reason something requests directly from api.tv4play.se, which is bad
      @hash['source'] = @hash['source'].sub(%r{^http://api\.tv4play\.se/}, 'http://webapi.tv4play.se/')
    end

    def keys
      @hash.keys
    end

    def [](symbol)
      @hash[symbol.to_s] || @hash[symbol]
    end

    def method_missing(symbol)
      @hash[symbol.to_s] || @hash[symbol]
    end

    private

    def unescape_source
      @hash['source'] &&= CGI.unescape(CGI.unescape(@hash['source']))
    end

    def unescape_signature
      @hash['signature'] &&= URI.unescape(@hash['signature'])
    end

    def merge_obfuscated
      if @hash["_"]
        decoded = Base64.decode64(CGI.unescape(@hash["_"]))
        decoded_hash = CGI.parse(decoded)
        @hash.delete "_"
        decoded_hash.map { |k, v| @hash[k] = (v.class == Array) ? v.first : v }
      end

      if @hash["-"]
        decoded = Base64.decode64(CGI.unescape(@hash["-"]))
        decoded_hash = Hash[*decoded.split('/').reject { |s| s.nil? || s.empty? }]
        @hash.delete "-"
        decoded_hash.map { |k, v| @hash[k] = (v.class == Array) ? v.first : v }
      end
    end
  end
end