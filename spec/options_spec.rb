require 'spec_helper'

def accepts_rezise_option?(resize)
  options = Imageproxy::Options.new("the-path", {'resize' => resize})
  options.check_parameters
  options.keys.include?('resize')
end

describe Imageproxy::Options do

  describe "#check_parameters" do
    it "allows some combinations of X and Y values for resize" do
      accepts_rezise_option?('1x2').should be_true
      accepts_rezise_option?('111x222').should be_true
      accepts_rezise_option?('111').should be_true
      accepts_rezise_option?('x222').should be_true
      accepts_rezise_option?('111x').should be_true

      accepts_rezise_option?('baaaah').should be_false
      accepts_rezise_option?('').should be_false
      accepts_rezise_option?(nil).should be_false

    end
  end

  describe "#remap_source" do
    it "leaves most urls alone" do
      options = Imageproxy::Options.new("the-path", {'source' => 'http://foo/bar'})
      options.source.should == 'http://foo/bar'
    end

    it "changes prima.tv4play.se requests to API4's proxy" do
      options = Imageproxy::Options.new("the-path", {'source' => 'http://prima.tv4play.se/multimedia/vman/VMan-P229/VMan-P2292392_OG.jpg'})
      options.source.should == 'http://webapi.tv4play.se/prima/multimedia/vman/VMan-P229/VMan-P2292392_OG.jpg'
    end
  end
end
