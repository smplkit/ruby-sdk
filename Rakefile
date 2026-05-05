# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: %i[rubocop spec]

# Override the bundler-supplied +rake release+. The release-prepare action
# in our CI workflow has already created and pushed the canonical git tag
# by the time this task runs, so bundler's source_control_push step would
# fail with "tag already exists" on every release. Skip directly to the
# gem-push step.
Rake::Task["release"].clear
desc "Build and push the gem (tag is owned by sdk-release-prepare)"
task release: %i[build release:rubygem_push]
