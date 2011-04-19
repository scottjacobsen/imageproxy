class Server
  def initialize()
    puts 'Initialize server'
    @dc = Dalli::Client.new()

    AWS::S3::Base.establish_connection!(
        :access_key_id     => ENV['AMAZON_KEY'],
        :secret_access_key => ENV['AMAZON_SECRET_KEY']
      )

    @bucketname = ENV['AMAZON_S3_BUCKET']
    @host = 'http://' + @bucketname + '.s3.amazonaws.com/'
  end
  def call(env)
    #p @dc.get('abc')
    request = Rack::Request.new(env)
    options = Options.new(request.path_info, request.params)
    case options.command
      when "convert", "process"
        if @dc.get(options.filename)
          puts 'File already exists'
          [302, {"Location" => @host + options.filename, "Content-Type" => "text/plain"}]
        else
          file = Convert.new(options).execute
          class << file
            alias to_path path
          end
          file.open
          AWS::S3::S3Object.store(options.filename, file, @bucketname,:access => :public_read)
          file.rewind
          @dc.set(options.filename, true)
          [200, {"Content-Type" => options.content_type}, file]
        end
      when "identify"
        [200, {"Content-Type" => "text/plain"}, Identify.new(options).execute]
      else
        [404, {"Content-Type" => "text/plain"}, "Not found"]
    end
  rescue
    STDERR.puts $!
    [500, {"Content-Type" => "text/plain"}, "Sorry, an internal error occurred"]
  end
end
