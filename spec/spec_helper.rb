# frozen_string_literal: true

require "hamachi"

class Binding
  def pry
    require 'pry'
    super
  end
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
end

