# frozen_string_literal: true

class Binding
  def pry
    require 'pry'
    super
  end
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
end

if ENV['SIMPLECOV']
  require 'simplecov'
  SimpleCov.start
end

require "hamachi"

