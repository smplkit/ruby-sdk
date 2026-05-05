# frozen_string_literal: true

require_relative "lib/smplkit/version"

# Derive the gem version at build time. We do not stamp version numbers into
# source files — the canonical version is the most recent +vX.Y.Z+ git tag
# created by +sdk-release-prepare+. Resolution order:
#
#   1. +SMPLKIT_GEM_VERSION+ env var (set by the release workflow from
#      +steps.prep.outputs.version+ — covers manual_version dispatches and
#      cases where the tag isn't fetched).
#   2. The most recent +v*+ git tag in the working checkout.
#   3. +Smplkit::VERSION+ from +lib/smplkit/version.rb+ (only used for
#      local development — fresh-fork or pre-release checkouts that
#      legitimately have no tags).
gem_version_for_build = lambda do
  env_override = ENV.fetch("SMPLKIT_GEM_VERSION", "").strip
  next env_override.sub(/\Av/, "") unless env_override.empty?

  git_tag = `git describe --tags --abbrev=0 --match "v*" 2>/dev/null`.to_s.strip
  next git_tag.sub(/\Av/, "") if git_tag.match?(/\Av\d+\.\d+\.\d+/)

  Smplkit::VERSION
end

Gem::Specification.new do |spec|
  spec.name = "smplkit"
  spec.version = gem_version_for_build.call
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

  spec.add_dependency "async", "~> 2.39"
  spec.add_dependency "async-http", "~> 0.95"
  spec.add_dependency "async-websocket", "~> 0.30"
  spec.add_dependency "concurrent-ruby", "~> 1.2"
  spec.add_dependency "faraday", "~> 2.7"
  spec.add_dependency "faraday-multipart", "~> 1.0"
  spec.add_dependency "json_logic", "~> 0.0"
end
