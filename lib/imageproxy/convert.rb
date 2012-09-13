require File.join(File.expand_path(File.dirname(__FILE__)), "command")

require 'RMagick'
require 'rest_client'
require 'digest'

module Imageproxy
  class Convert < Imageproxy::Command
    attr_reader :options

    class ConvertedImage
      attr_reader :image_blob, :source_headers

      def initialize(image_blob, source_headers, options, cache_time, modified = true)
        @modified = modified
        @image_blob, @source_headers, @options, @cache_time = image_blob, source_headers, options, cache_time
      end

      def source_etag
        if source_headers[:etag]
          match = /(?:W\/)?\"(.*)\"/.match(source_headers[:etag])
          return nil unless match
          match[1]
        end
      end

      def content_type
        source_headers[:content_type]
      end

      def empty?
        @image_blob.empty?
      end

      def size
        return 0 if @image_blob.nil?
        @image_blob.bytesize
      end

      def stream
        StringIO.new(@image_blob)
      end

      def headers
        cache_time = @cache_time || 86400
        headers = {"Cache-Control" => "public, max-age=#{cache_time}" }

        if modified?
          headers.merge!("Content-Length" => size.to_s,
                         "Content-Type" => content_type)
        end

        if source_etag
          quoted_original_etag = source_etag.tr('"', '')
          # Using weak etag (the prefixed "W"), since the image transformations
          # aren't necessarily byte-to-byte identical
          headers.merge!("ETag" => %{W/"#{quoted_original_etag}-#{transformation_checksum(@options)}"})
        end
        headers
      end

      def transformation_checksum(options)
        buffer = options.keys.sort.collect { |key|
          "#{key}:#{options[key]}"
        }.flatten.join(':')
        Digest::MD5.hexdigest(buffer)[0..8]
      end

      def modified?
        @modified
      end
    end

    def initialize(options, cache_time, requested_etag = nil)
      @options = options
      @cache_time = cache_time
      @requested_etag = requested_etag
      if (!(options.resize || options.thumbnail || options.rotate || options.flip || options.format || options.quality))
        raise "Missing action or illegal parameter value"
      end
    end

    def process_image(original_image)
      image = Magick::Image.from_blob(original_image).first

      if options.resize
        x, y = options.resize.split('x').collect(&:to_i)

        if options.shape == "trimcut"

          # Add (near) black border to aid trimming
          # Near black, because we can use a lower fuzz level
          # and digitized TV can have black level 16/255 anyhow.

          image.fuzz = "20%"
          image.trim!(true)
          image.crop_resized!(x, y, Magick::CenterGravity)

          # According to our heuristics we should really
          # use gravity moved 15% below of center

        elsif options.shape == "cut"
          image.crop_resized!(x, y, Magick::CenterGravity)
        else
          image.change_geometry(options.resize) do |proportional_x, proportional_y, img|
            img.resize!(proportional_x, proportional_y)
          end
        end
      end

      image.strip! # Remove EXIF garbage
      image
    end

    def execute(user_agent=nil, timeout=nil)
      user_agent = user_agent || "imageproxy"

      request_options = {
              :timeout => timeout,
              :user_agent => user_agent,
              :accept => '*/*'
      }
      if @requested_etag && @requested_etag =~ %r{^(?:W\/)?"(.+)\-(.*?)"$}
        source_etag = $1
        request_options[:if_none_match] = %{"#{source_etag}"}
      end

      begin
        response = RestClient.get(options.source, request_options)
      rescue RestClient::NotModified => e
        return ConvertedImage.new(nil, e.response.headers, options, @cache_time, false)
      end

      original_image = response.to_str
      image = process_image(original_image)

      ConvertedImage.new(image.to_blob, response.headers, options, @cache_time)
    end
  end
end
