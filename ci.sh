#!/bin/bash --login
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"  # This loads RVM 
rvm rvmrc load
bundle install 
COVERAGE=on bundle exec rake ci:setup:rspec spec
