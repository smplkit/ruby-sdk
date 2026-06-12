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
      def raw
        @data
      end

      def raw=(value)
        @data = value.dup
      end

      # Canonical ordering of STANDARD environments. Empty list if unset.
      def environment_order
        Array(@data["environment_order"] || [])
      end

      def environment_order=(value)
        @data["environment_order"] = value.to_a
      end

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

      def _apply(other)
        @data = other.raw.dup
      end
    end
  end
end
