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
require_relative "smplkit/client"

require_relative "smplkit/railtie" if defined?(Rails::Railtie)
