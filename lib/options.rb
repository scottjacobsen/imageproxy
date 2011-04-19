class Options
  def initialize(path, query_params)
    params_from_path = path.split('/').reject { |s| s.nil? || s.empty? }
    command = params_from_path.shift

    @hash = Hash[*params_from_path]
    @hash['command'] = command
    @hash.merge! query_params

    unescape_source
  end

  def method_missing(symbol)
    @hash[symbol.to_s] || @hash[symbol]
  end

  def content_type
    MIME::Types.of(@hash['source']).first.content_type
  end

  def hash
    Digest::MD5.hexdigest(@hash["source"] + "|" +@hash['resize'].to_s + "|"+ @hash['command'] + "|"+ @hash['shape'].to_s + "|"+ @hash['background'].to_s + "|"+ @hash['rotate'].to_s)
  end

  def filename
    hash.to_s + "." + MIME::Types.of(@hash['source']).first.extensions.first
  end

  private
  
  def unescape_source
    if @hash['source']
      @hash['source'] = CGI.unescape(CGI.unescape(@hash['source']))
    end
  end
end