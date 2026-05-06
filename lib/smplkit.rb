# frozen_string_literal: true

# Official Ruby SDK for the smplkit platform.
#
#   require "smplkit"
#
#   client = Smplkit::Client.new(environment: "production", service: "my-svc")
#   flag = client.flags.boolean_flag("checkout-v2", default: false)
#   flag.get
module Smplkit
end

require_relative "smplkit/version"

# Load the generated OpenAPI client trees. Each tree under
# +lib/smplkit/_generated/<svc>/lib+ uses internal +require+ paths like
# +smplkit_<svc>_client/api_client+, so the directory has to be on
# +$LOAD_PATH+ before its top-level entry is required.
%w[app audit config flags logging].each do |svc|
  generated_lib = File.expand_path("smplkit/_generated/#{svc}/lib", __dir__)
  $LOAD_PATH.unshift(generated_lib) if File.directory?(generated_lib)
end

# The openapi-generator-produced files declare +module SmplkitGeneratedClient::App+
# without first declaring the parent module. MRI requires it to already
# exist, so pre-declare here.
module SmplkitGeneratedClient # rubocop:disable Style/OneClassPerFile
end

%w[smplkit_app_client smplkit_audit_client smplkit_config_client smplkit_flags_client
   smplkit_logging_client].each do |gem_lib|
  require gem_lib
rescue LoadError
  # Generated tree may be intentionally absent in development snapshots —
  # the wrapper layer falls back gracefully.
end

require_relative "smplkit/errors"
require_relative "smplkit/debug"
require_relative "smplkit/helpers"
require_relative "smplkit/log_level"
require_relative "smplkit/context"
require_relative "smplkit/config_resolution"
require_relative "smplkit/metrics"
require_relative "smplkit/ws"
require_relative "smplkit/flags/types"
require_relative "smplkit/flags/models"
require_relative "smplkit/flags/helpers"
require_relative "smplkit/flags/client"
require_relative "smplkit/config/models"
require_relative "smplkit/config/helpers"
require_relative "smplkit/config/client"
require_relative "smplkit/logging/levels"
require_relative "smplkit/logging/normalize"
require_relative "smplkit/logging/sources"
require_relative "smplkit/logging/models"
require_relative "smplkit/logging/helpers"
require_relative "smplkit/logging/adapters/base"
require_relative "smplkit/logging/adapters/stdlib_logger_adapter"
require_relative "smplkit/logging/client"
require_relative "smplkit/management/types"
require_relative "smplkit/management/models"
require_relative "smplkit/management/buffer"
require_relative "smplkit/management/client"
require_relative "smplkit/audit/buffer"
require_relative "smplkit/audit/events"
require_relative "smplkit/audit/client"
require_relative "smplkit/client"

require_relative "smplkit/railtie" if defined?(Rails::Railtie)
