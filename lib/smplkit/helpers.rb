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

    # Recursively convert all Hash keys to strings. Used at the wrapper
    # boundary to normalise the symbol-keyed hashes the openapi-generator
    # client emits when deserialising ``Hash<String, Object>`` fields
    # (a by-product of its ``JSON.parse(symbolize_names: true)`` call).
    # The other SDKs (Python, TypeScript, Go, Java, C#) all return string
    # keys; this keeps Ruby consistent with that contract.
    def deep_stringify_keys(value)
      case value
      when Hash
        value.each_with_object({}) { |(k, v), out| out[k.to_s] = deep_stringify_keys(v) }
      when Array
        value.map { |v| deep_stringify_keys(v) }
      else
        value
      end
    end
  end
end
