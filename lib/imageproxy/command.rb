module Imageproxy
  class Command
    protected

    def to_path(obj)
      obj.respond_to?(:path) ? obj.path : obj.to_s
    end

    def output_to_string(output)
      output.readlines.join("").chomp
    end
  end
end