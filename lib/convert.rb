class Convert
  attr_reader :options
  
  def initialize(options)
    @options = options
  end

  def execute
    execute_command %'curl -s "#{options.source}" | convert - #{convert_options} #{new_format}#{file.path}'
    file
  end

  def convert_options
    convert_options = []
    convert_options << "-resize #{resize_thumbnail_options(options.resize)}" if options.resize
    convert_options << "-thumbnail #{resize_thumbnail_options(options.thumbnail)}" if options.thumbnail
    convert_options << "-flop" if options.flip == "horizontal"
    convert_options << "-flip" if options.flip == "vertical"
    convert_options << rotate_options if options.rotate
    convert_options << "-colors 256" if options.format == "png8"
    convert_options << "-quality #{options.quality}" if options.quality
    convert_options << interlace_options if options.progressive
    convert_options.join " "
  end

  def resize_thumbnail_options(size)
    case options.shape
      when "cut"
        "#{size}^ -gravity center -extent #{size}"
      when "preserve"
        size
      when "pad"
        background = options.background ? %|"#{options.background}"| : %|none -matte|
        "#{size} -background #{background} -gravity center -extent #{size}"
      else
        size
    end
  end

  def rotate_options
    if options.rotate.to_f % 90 == 0
      "-rotate #{options.rotate}"
    else
      background = options.background ? %|"#{options.background}"| : %|none|
      "-background #{background} -matte -rotate #{options.rotate}"
    end
  end

  def interlace_options
    case options.progressive
      when "true"
        "-interlace JPEG"
      when "false"
        "-interlace none"
      else
        ""
    end
  end

  def new_format
    options.format ? "#{options.format}:" : ""
  end

  def file
    @tempfile ||= Tempfile.new("imageproxy").tap(&:close)
  end
    def execute_command(command_line)
    stdin, stdout, stderr = Open3.popen3(command_line)
    [output_to_string(stdout), output_to_string(stderr)].join("")
  end

  def to_path(obj)
    obj.respond_to?(:path) ? obj.path : obj.to_s
  end

  def output_to_string(output)
    output.readlines.join("").chomp
  end
end