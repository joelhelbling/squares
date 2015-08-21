$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'pry'
require 'rspec-given'
require 'squares'

# load fixtures
Dir['spec/fixtures/**/*.rb'].each do |fixture|
  require File.expand_path(fixture)
end
