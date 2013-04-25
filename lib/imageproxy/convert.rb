require File.join(File.expand_path(File.dirname(__FILE__)), "command")

require 'RMagick'
require 'rest_client'
require 'digest'

module Imageproxy
  class Convert < Imageproxy::Command
    attr_reader :options

    class ConvertedImage
      attr_reader :image_blob, :source_headers

      def initialize(image_blob, source_headers, options, cache_time, modified = true, exists = true)
        @modified = modified
        @exists = exists
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
        headers = {"Cache-Control" => "public, max-age=#{cache_time}"}

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
        headers.merge!("Last-Modified" => Time.now.httpdate)
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

      def exists?
        @exists
      end
    end

    def initialize(options, cache_time, requested_etag = nil)
      @options = options
      @cache_time = cache_time
      @requested_etag = requested_etag
    end

    def process_image(original_image)
      image = Magick::Image.from_blob(original_image).first

      if options.resize
        x, y = options.resize.split('x').collect(&:to_i)

        if y.nil? && options.aspect_ratio
          aspect_ratio = options.aspect_ratio.split(':').collect(&:to_f)
          y = (x / (aspect_ratio.first / aspect_ratio.last)).round
        end


        if options.shape == "trimcut"

          # Add black border to aid trimming
          image.border!(5, 5, 'black')

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

    def execute(user_agent=nil, timeout=0)
      user_agent = user_agent || "imageproxy"

      request_options = {
              :user_agent => user_agent,
              :accept => '*/*'
      }
      if @requested_etag && @requested_etag =~ %r{^(?:W\/)?"(.+)\-(.*?)"$}
        source_etag = $1
        request_options[:if_none_match] = %{"#{source_etag}"}
      end

      begin
        response = RestClient::Request.execute(:method => :get, :url => options.source, :headers => request_options, :max_redirects => 0, :timeout => timeout, :open_timeout => timeout)

      rescue RestClient::NotModified => e
        return ConvertedImage.new(nil, e.response.headers, options, @cache_time, false)
      rescue RestClient::ResourceNotFound
        return image_404
      rescue RestClient::MaxRedirectsReached
        return image_404
      rescue URI::InvalidURIError
        # Not really a 404, but simpler than adding 400 error handling
        return image_404
      end

      original_image = response.to_str
      begin
        image = process_image(original_image)
      rescue Magick::ImageMagickError
        STDERR.puts "Corrupt image: #{options.source}"
        return image_404
      end

      image_blob = image.to_blob {
        self.quality = ENV['IMAGE_QUALITY'].to_i if ENV['IMAGE_QUALITY'] # From 0 to 100, where 100 is best. Default is claimed to be 75.
      }
      ConvertedImage.new(image_blob, response.headers, options, @cache_time)
    end

    def image_404
      ConvertedImage.new(nil, {}, options, @cache_time, true, false)
    end
  end
end
