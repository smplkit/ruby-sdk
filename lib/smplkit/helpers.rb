# frozen_string_literal: true

module Smplkit
  module Helpers
    module_function

    # Convert a slug-style key to a human-readable display name.
    #
    #   key_to_display_name("checkout-v2")    # => "Checkout V2"
    #   key_to_display_name("user_service")   # => "User Service"
    def key_to_display_name(key)
      key.tr("-_", "  ").split.map(&:capitalize).join(" ")
    end
  end
end
