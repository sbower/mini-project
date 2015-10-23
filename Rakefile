require 'rubygems'
require 'cucumber'
require 'cucumber/rake/task'

task :cucumber => 'cucumber:ok'
task :default => :cucumber

namespace :cucumber do
  Cucumber::Rake::Task.new(:ok, 'Run features that should pass') do |t|
    t.fork = true # You may get faster startup if you set this to false
    t.cucumber_opts = "--format pretty"
    t.profile = 'default'
  end

  Cucumber::Rake::Task.new(:wip, 'Run features that are being worked on') do |t|
    t.fork = true # You may get faster startup if you set this to false
    t.cucumber_opts = "--format pretty"
    t.profile = 'wip'
  end

  Cucumber::Rake::Task.new(:rerun, 'Record failing features and run only them if any exist') do |t|
    t.fork = true # You may get faster startup if you set this to false
    t.cucumber_opts = "--format pretty"
    t.profile = 'rerun'
  end

  task :all => [:ok, :wip]
end
