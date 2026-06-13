# frozen_string_literal: true

module Smplkit
  module Account
    # Active-record account-settings model.
    #
    # The wire format is opaque JSON. Documented keys are exposed as typed
    # properties; unknown keys live in +raw+. +save+ writes the full settings
    # object back.
    class AccountSettings
      def initialize(client = nil, data: nil)
        @client = client
        @data = data ? data.dup : {}
      end

      # The full settings dict. Mutations are persisted on save.
      #
      # @return [Hash] The full settings dict.
      def raw
        @data
      end

      # Replace the full settings dict.
      #
      # @param value [Hash] The new settings dict.
      # @return [void]
      def raw=(value)
        @data = value.dup
      end

      # Canonical ordering of STANDARD environments. Empty list if unset.
      #
      # @return [Array<String>] The environment ids in canonical order.
      def environment_order
        Array(@data["environment_order"] || [])
      end

      # Set the canonical ordering of STANDARD environments.
      #
      # @param value [Array<String>] The environment ids in canonical order.
      # @return [void]
      def environment_order=(value)
        @data["environment_order"] = value.to_a
      end

      # Write the full settings object back to the account.
      #
      # @return [AccountSettings] +self+, updated with the server response.
      # @raise [RuntimeError] If this model was constructed without a client
      #   (e.g. built by hand rather than returned from +get+).
      def save
        raise "AccountSettings was constructed without a client; cannot save" if @client.nil?

        other = @client._save(@data)
        _apply(other)
        self
      end
      alias save! save

      def to_s
        "AccountSettings(#{@data.inspect})"
      end
      alias inspect to_s

      # @api private
      def _apply(other)
        @data = other.raw.dup
      end
    end
  end
end
