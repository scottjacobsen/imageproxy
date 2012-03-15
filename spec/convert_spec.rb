
require 'spec_helper'

describe Imageproxy::Convert do

  context "When requesting a resize" do
    before do
      @options = mock("options")
      @options.stub(:resize).and_return("123x456")
      @options.stub(:source).and_return("http://example.com/sample.png")
      @options.stub(:shape).and_return(nil)
      @options.stub(:keys).and_return([:resize, :source])
      @options.stub(:[]).with(:resize).and_return("123x456")
      @options.stub(:[]).with(:source).and_return("http://example.com/sample.png")

      response = mock("response")
      response.stub(:headers).and_return({:etag => '"SOMEETAG"'})
      RestClient.stub(:get).and_return(response)
      response.stub(:to_str).and_return(open('public/sample.png').read)
    end

    it "resizes the image" do
      result = Imageproxy::Convert.new(@options).execute("test agent", 1234)

      image = Magick::Image.from_blob(result.stream.read).first
      image.columns.should == 123
      image.rows.should == 71
    end

    it "creates an ETag based on the source's ETag and the options" do
      result = Imageproxy::Convert.new(@options).execute("test agent", 1234)

      result.headers(1233, @options)['ETag'].should =~ %r{^W\/"SOMEETAG\-.+"$}
    end
  end
end
