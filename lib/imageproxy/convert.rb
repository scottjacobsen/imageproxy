require File.join(File.expand_path(File.dirname(__FILE__)), "command")

require 'RMagick'
require 'rest_client'
require 'digest'

module Imageproxy
  class Convert < Imageproxy::Command
    attr_reader :options

    class ConvertedImage
      attr_reader :image_blob, :source_headers

      def initialize(image_blob, source_headers)
        @image_blob, @source_headers = image_blob, source_headers
      end

      def etag
        if source_headers[:etag]
          if source_headers[:etag] =~ /(?:W\/)?\"(.*)\"/
            $1
          else
            nil
          end
        end
      end

      def content_type
        source_headers[:content_type]
      end

      def empty?
        @image_blob.empty?
      end

      def size
        @image_blob.bytesize
      end

      def stream
        StringIO.new(@image_blob)
      end

      def headers(cache_time, options)
        cache_time = cache_time || 86400
        headers = {"Cache-Control" => "public, max-age=#{cache_time}, must-revalidate",
                   "Content-Length" => size.to_s,
                   "Content-Type" => content_type}
        if etag
          quoted_original_etag = etag.tr('"', '')
          headers.merge!("ETag" => %{W/"#{quoted_original_etag}-#{transformation_checksum(options)}"})
        end
        headers
      end

      def transformation_checksum(options)
        buffer = options.keys.sort.collect { |key|
          "#{key}:#{options[key]}"
        }.flatten.join(':')
        Digest::MD5.hexdigest(buffer)[0..8]
      end
    end

    def initialize(options)
      @options = options
      if (!(options.resize || options.thumbnail || options.rotate || options.flip || options.format || options.quality))
        raise "Missing action or illegal parameter value"
      end
    end

    def execute(user_agent=nil, timeout=nil)
      user_agent = user_agent || "imageproxy"

      response = RestClient.get(options.source, :timeout => timeout, :headers => {'User-Agent' => user_agent})

      original_image = response.to_str
      image = Magick::Image.from_blob(original_image).first

      if options.resize
        x, y = options.resize.split('x').collect(&:to_i)

        if options.shape == "cut"
          image.crop_resized!(x, y, Magick::CenterGravity)
        else
          image.change_geometry(options.resize) do |proportional_x, proportional_y, img|
            img.resize!(proportional_x, proportional_y)
          end
        end
      end

      image.strip! # Remove EXIF garbage

      ConvertedImage.new(image.to_blob, response.headers)
    end
  end
end