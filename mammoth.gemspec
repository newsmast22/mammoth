# frozen_string_literal: true

$:.push File.expand_path("../lib", __FILE__)
require_relative "lib/mammoth/version"

Gem::Specification.new do |spec|
  spec.name = "mammoth"
  spec.version = Mammoth::VERSION
  spec.authors = ["yarzar"]
  spec.email = ["yarzarminwai97@gmail.com"]

  spec.summary = "Newsmast gem to provide customized APIs"
  spec.description = "Newsmast gem to provide customized APIs"
  spec.homepage = "https://github.com/newsmast22/mammoth"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://github.com/newsmast22/mammoth"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/newsmast22/mammoth"
  spec.metadata["changelog_uri"] = "https://github.com/newsmast22/mammoth"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html

  spec.add_dependency "rails", "~> 6.1"
  spec.add_dependency "byebug"
  spec.add_dependency "feedjira"
  spec.add_dependency 'httparty'
end
