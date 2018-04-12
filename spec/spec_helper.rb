$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'squares'
require 'pry'
require 'rspec-given'

# load fixtures
Dir['spec/fixtures/**/*.rb'].each do |fixture|
  require File.expand_path(fixture)
end
