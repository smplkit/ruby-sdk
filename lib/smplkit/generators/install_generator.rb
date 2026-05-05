# frozen_string_literal: true

require "rails/generators"

module Smplkit
  module Generators
    # Generates +config/initializers/smplkit.rb+ for Rails apps.
    #
    #   rails generate smplkit:install
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def create_initializer_file
        create_file "config/initializers/smplkit.rb", initializer_contents
      end

      def initializer_contents
        <<~RUBY
          # frozen_string_literal: true

          # smplkit configuration. Anything you don't set here resolves through
          # the standard SMPLKIT_* env vars or the ~/.smplkit profile file.
          Rails.application.configure do
            config.smplkit.environment = Rails.env
            config.smplkit.service = "your-service-name"
            # config.smplkit.api_key = ENV["SMPLKIT_API_KEY"]

            # Optional: per-request context. The provider receives the Rack env
            # and returns an Array of Smplkit::Context. Returning nil/[] is fine.
            #
            # config.smplkit.context_provider = ->(env) {
            #   user = env["warden"]&.user
            #   next [] unless user
            #
            #   [Smplkit::Context.new("user", user.id.to_s, plan: user.plan)]
            # }
          end
        RUBY
      end
    end
  end
end
