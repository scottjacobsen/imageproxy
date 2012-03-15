require File.join(File.expand_path(File.dirname(__FILE__)), "command")

require 'RMagick'
require 'rest_client'

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