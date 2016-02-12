require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc "a console for playing with Squares"
task :play do
  require './lib/squares'
  Dir['spec/fixtures/**/*.rb'].each do |fixture|
    require File.expand_path(fixture)
  end
  require 'pry'
  binding.pry
end
