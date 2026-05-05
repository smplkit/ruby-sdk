# frozen_string_literal: true

require_relative "lib/smplkit/version"

Gem::Specification.new do |spec|
  spec.name = "smplkit"
  spec.version = Smplkit::VERSION
  spec.authors = ["Smpl Solutions LLC"]
  spec.email = ["support@smplkit.com"]

  spec.summary = "Official Ruby SDK for the smplkit platform"
  spec.description = "Ruby SDK for the smplkit platform — flags, config, and logging APIs " \
                     "with runtime evaluation, live updates, and management operations."
  spec.homepage = "https://www.smplkit.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/smplkit/ruby-sdk"
  spec.metadata["documentation_uri"] = "https://docs.smplkit.com"
  spec.metadata["changelog_uri"] = "https://github.com/smplkit/ruby-sdk/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "lib/**/*.rb",
    "lib/**/*.json",
    "sig/**/*.rbs",
    "README.md",
    "LICENSE",
    "CHANGELOG.md"
  ].reject { |f| File.directory?(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "concurrent-ruby", "~> 1.2"
  spec.add_dependency "faraday", "~> 2.7"
  spec.add_dependency "faraday-multipart", "~> 1.0"
  spec.add_dependency "json_logic", "~> 0.0"
end
