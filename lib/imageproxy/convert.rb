require File.join(File.expand_path(File.dirname(__FILE__)), "command")

require 'RMagick'

module Imageproxy
  class Convert < Imageproxy::Command
    attr_reader :options

    def initialize(options)
      @options = options
      if (!(options.resize || options.thumbnail || options.rotate || options.flip || options.format || options.quality))
        raise "Missing action or illegal parameter value"
      end
    end

    def execute(user_agent=nil, timeout=nil)
      user_agent = user_agent || "imageproxy"

      request = Curl::Easy.perform(options.source) do |curl|
        curl.timeout = timeout if timeout
        curl.useragent = user_agent if user_agent
      end
      original_image = request.body_str

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

      image.to_blob
    end

    #def convert_options
    #  convert_options = []
    #  convert_options << "-resize #{resize_thumbnail_options(options.resize)}" if options.resize
    #  convert_options << "-thumbnail #{resize_thumbnail_options(options.thumbnail)}" if options.thumbnail
    #  convert_options << "-flop" if options.flip == "horizontal"
    #  convert_options << "-flip" if options.flip == "vertical"
    #  convert_options << rotate_options if options.rotate
    #  convert_options << "-colors 256" if options.format == "png8"
    #  convert_options << "-quality #{options.quality}" if options.quality
    #  convert_options << interlace_options if options.progressive
    #  convert_options.join " "
    #end
    #
    #def resize_thumbnail_options(size)
    #  case options.shape
    #    when "cut"
    #      "#{size}^ -gravity center -extent #{size}"
    #    when "preserve"
    #      size
    #    when "pad"
    #      background = options.background ? %|"#{options.background}"| : %|none -matte|
    #      "#{size} -background #{background} -gravity center -extent #{size}"
    #    else
    #      size
    #  end
    #end
    #
    #def rotate_options
    #  if options.rotate.to_f % 90 == 0
    #    "-rotate #{options.rotate}"
    #  else
    #    background = options.background ? %|"#{options.background}"| : %|none|
    #    "-background #{background} -matte -rotate #{options.rotate}"
    #  end
    #end
    #
    #def interlace_options
    #  case options.progressive
    #    when "true"
    #      "-interlace JPEG"
    #    when "false"
    #      "-interlace none"
    #    else
    #      ""
    #  end
    #end
    #
    #def new_format
    #  options.format ? "#{options.format}:" : ""
    #end
  end
end