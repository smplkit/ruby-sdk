# frozen_string_literal: true

module Smplkit
  module Logging
    # Logger name normalization.
    #
    # Replace +/+ with +.+, replace +:+ with +.+, lowercase everything.
    #
    # @api private
    module Normalize
      module_function

      def normalize_logger_name(name)
        name.to_s.tr("/:", "..").downcase
      end
    end
  end
end
