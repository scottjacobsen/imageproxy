unless ENV["RACK_ENV"] == "stage" || ENV["RACK_ENV"] == "production"
end
require 'heroku-api'

namespace :scale do
  desc "Scale dynos to extrasmall mode"
  task :extrasmall => :environment do
  scale_dynos(3)
  end
  
  desc "Scale dynos to small mode"
  task :small => :environment do
  scale_dynos(15)
  end

  desc "Scale dynos to medium mode"
  task :medium => :environment do
  scale_dynos(25)
  end

  desc "Scale dynos to extralarge mode"
  task :large => :environment do
  scale_dynos(35)
  end

  desc "Scale dynos to extralarge mode"
  task :extralarge => :environment do
  scale_dynos(50)
  end

  desc "Scale dynos to panic mode"
  task :panic => :environment do
  scale_dynos(80)
  end

  def scale_dynos(dynos)
  heroku = Heroku::API.new(:api_key => ENV['MY_API_KEY'])
  heroku.post_ps_scale(ENV['APP_NAME'], 'web', dynos)        
  end
end

