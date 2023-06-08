# frozen_string_literal: true
require "./lib/hamachi/version"


Gem::Specification.new do |spec|
  spec.name = "hamachi"
  spec.version = Hamachi::VERSION
  spec.authors = ["Adrian Kuhn"]
  spec.email = ["akuhn@iam.unibe.ch"]

  spec.summary = "Flexible and type-safe representation of JSON data."
  spec.homepage = "https://github.com/akuhn/hamachi"
  spec.required_ruby_version = ">= 1.9.3"

  if spec.respond_to? :metadata
    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata['source_code_uri'] = "https://github.com/akuhn/hamachi"
    spec.metadata['changelog_uri'] = "https://github.com/akuhn/hamachi/blob/master/lib/hamachi/version.rb"
  end

  spec.require_paths = ["lib"]
  spec.files = %w{
    README.md
    lib/hamachi.rb
    lib/hamachi/model.rb
    lib/hamachi/ext.rb
    lib/hamachi/enumerable_ext.rb
    lib/hamachi/version.rb
  }

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
