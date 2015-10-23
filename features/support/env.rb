begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end
require 'capybara'
require 'capybara/dsl'
require 'capybara/cucumber'

require 'test/unit'

World(Test::Unit::Assertions)

Capybara.default_driver = :selenium
Capybara.app_host = ENV["HOST"]
Capybara.run_server = false
