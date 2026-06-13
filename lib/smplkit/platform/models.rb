# frozen_string_literal: true

module Smplkit
  module Platform
    # Accept Color, hex string, or nil; reject anything else.
    #
    # @api private
    def self.coerce_color(value)
      return value if value.nil? || value.is_a?(Color)
      return Color.new(value) if value.is_a?(String)

      raise TypeError, "color must be a Color, hex string, or nil; got #{value.class}: #{value.inspect}"
    end

    # Environment resource (sync). Mutate fields, then call +save+.
    class Environment
      attr_accessor :id, :name, :classification, :created_at, :updated_at
      attr_reader :color

      # Create an environment instance.
      #
      # Prefer +client.platform.environments.new(...)+ to build an unsaved
      # environment; this constructor is also used internally to wrap server
      # responses.
      #
      # @param client [EnvironmentsClient, nil] Client used to persist and
      #   delete this environment. +nil+ produces a detached instance that
      #   cannot +save+.
      # @param name [String] Display name shown in the Console.
      # @param id [String, nil] Stable, human-readable identifier for the
      #   environment.
      # @param color [Color, String, nil] Accent color, as a +Color+ or a CSS
      #   hex string. Defaults to no color.
      # @param classification [String] Whether the environment participates in
      #   the standard environment ordering. Defaults to
      #   +EnvironmentClassification::STANDARD+.
      # @param created_at [String, nil] When the environment was created. Set
      #   on instances returned by the server; leave +nil+ for unsaved ones.
      # @param updated_at [String, nil] When the environment was last updated.
      #   Set on instances returned by the server; leave +nil+ for unsaved ones.
      def initialize(client = nil, name:, id: nil, color: nil,
                     classification: EnvironmentClassification::STANDARD,
                     created_at: nil, updated_at: nil)
        @client = client
        @id = id
        @name = name
        @color = Platform.coerce_color(color)
        @classification = classification
        @created_at = created_at
        @updated_at = updated_at
      end

      # Set the accent color, coercing the value to a +Color+.
      #
      # @param value [Color, String, nil] A +Color+, a CSS hex string, or +nil+
      #   to clear the color.
      # @return [void]
      def color=(value)
        @color = Platform.coerce_color(value)
      end

      # Create or update this environment on the server.
      #
      # @return [Environment] +self+, updated with the server response.
      # @raise [RuntimeError] If this environment was constructed without a
      #   client.
      def save
        raise "Environment was constructed without a client; cannot save" if @client.nil?

        other = @created_at.nil? ? @client._create(self) : @client._update(self)
        _apply(other)
        self
      end
      alias save! save

      # Delete this environment from the server.
      #
      # @return [void]
      # @raise [RuntimeError] If this environment was constructed without a
      #   client or id.
      def delete
        raise "Environment was constructed without a client or id; cannot delete" if @client.nil? || @id.nil?

        @client.delete(@id)
      end
      alias delete! delete

      def to_s
        "Environment(id=#{@id.inspect}, name=#{@name.inspect}, classification=#{@classification.inspect})"
      end
      alias inspect to_s

      # @api private
      def _apply(other)
        @id = other.id
        @name = other.name
        @color = other.color
        @classification = other.classification
        @created_at = other.created_at
        @updated_at = other.updated_at
      end
    end

    # Service resource (sync). Mutate fields, then call +save+.
    class Service
      attr_accessor :id, :name, :created_at, :updated_at

      # Create a service instance.
      #
      # Prefer +client.platform.services.new(...)+ to build an unsaved service;
      # this constructor is also used internally to wrap server responses.
      #
      # @param client [ServicesClient, nil] Client used to persist and delete
      #   this service. +nil+ produces a detached instance that cannot +save+.
      # @param name [String] Display name shown in the Console.
      # @param id [String, nil] Stable, human-readable identifier for the
      #   service.
      # @param created_at [String, nil] When the service was created. Set on
      #   instances returned by the server; leave +nil+ for unsaved ones.
      # @param updated_at [String, nil] When the service was last updated. Set
      #   on instances returned by the server; leave +nil+ for unsaved ones.
      def initialize(client = nil, name:, id: nil, created_at: nil, updated_at: nil)
        @client = client
        @id = id
        @name = name
        @created_at = created_at
        @updated_at = updated_at
      end

      # Create or update this service on the server.
      #
      # @return [Service] +self+, updated with the server response.
      # @raise [RuntimeError] If this service was constructed without a client.
      def save
        raise "Service was constructed without a client; cannot save" if @client.nil?

        other = @created_at.nil? ? @client._create(self) : @client._update(self)
        _apply(other)
        self
      end
      alias save! save

      # Delete this service from the server.
      #
      # @return [void]
      # @raise [RuntimeError] If this service was constructed without a client
      #   or id.
      def delete
        raise "Service was constructed without a client or id; cannot delete" if @client.nil? || @id.nil?

        @client.delete(@id)
      end
      alias delete! delete

      def to_s
        "Service(id=#{@id.inspect}, name=#{@name.inspect})"
      end
      alias inspect to_s

      # @api private
      def _apply(other)
        @id = other.id
        @name = other.name
        @created_at = other.created_at
        @updated_at = other.updated_at
      end
    end

    # A context type resource (e.g. "user", "account").
    class ContextType
      attr_accessor :id, :name, :attributes, :created_at, :updated_at

      # Create a context-type instance.
      #
      # Prefer +client.platform.context_types.new(...)+ to build an unsaved
      # context type; this constructor is also used internally to wrap server
      # responses.
      #
      # @param client [ContextTypesClient, nil] Client used to persist and
      #   delete this context type. +nil+ produces a detached instance that
      #   cannot +save+.
      # @param name [String] Display name shown in the Console.
      # @param id [String, nil] Stable, human-readable identifier for the
      #   context type.
      # @param attributes [Hash, nil] Known-attribute slots, keyed by attribute
      #   name, with a metadata dict per slot. Defaults to no declared
      #   attributes.
      # @param created_at [String, nil] When the context type was created. Set
      #   on instances returned by the server; leave +nil+ for unsaved ones.
      # @param updated_at [String, nil] When the context type was last updated.
      #   Set on instances returned by the server; leave +nil+ for unsaved ones.
      def initialize(client = nil, name:, id: nil, attributes: nil, created_at: nil, updated_at: nil)
        @client = client
        @id = id
        @name = name
        @attributes = attributes ? deep_dup_attrs(attributes) : {}
        @created_at = created_at
        @updated_at = updated_at
      end

      # Add a known-attribute slot. Local-only; call +save+ to persist.
      #
      # @param name [String] Attribute name to declare on this context type.
      # @param metadata [Hash] Arbitrary metadata stored for the attribute slot.
      # @return [void]
      def add_attribute(name, **metadata)
        @attributes[name] = stringify_meta(metadata)
      end

      # Remove a known-attribute slot. Local-only; call +save+ to persist.
      #
      # @param name [String] Attribute name to remove. A no-op if the attribute
      #   is not declared on this context type.
      # @return [void]
      def remove_attribute(name)
        @attributes.delete(name)
      end

      # Replace a known-attribute slot's metadata. Local-only; call +save+.
      #
      # @param name [String] Attribute name whose metadata to replace.
      # @param metadata [Hash] New metadata for the attribute slot, replacing
      #   any existing metadata.
      # @return [void]
      def update_attribute(name, **metadata)
        @attributes[name] = stringify_meta(metadata)
      end

      # Create or update this context type on the server.
      #
      # @return [ContextType] +self+, updated with the server response.
      # @raise [RuntimeError] If this context type was constructed without a
      #   client.
      def save
        raise "ContextType was constructed without a client; cannot save" if @client.nil?

        other = @created_at.nil? ? @client._create(self) : @client._update(self)
        _apply(other)
        self
      end
      alias save! save

      # Delete this context type from the server.
      #
      # @return [void]
      # @raise [RuntimeError] If this context type was constructed without a
      #   client or id.
      def delete
        raise "ContextType was constructed without a client or id; cannot delete" if @client.nil? || @id.nil?

        @client.delete(@id)
      end
      alias delete! delete

      def to_s
        "ContextType(id=#{@id.inspect}, name=#{@name.inspect})"
      end
      alias inspect to_s

      # @api private
      def _apply(other)
        @id = other.id
        @name = other.name
        @attributes = deep_dup_attrs(other.attributes)
        @created_at = other.created_at
        @updated_at = other.updated_at
      end

      private

      def stringify_meta(metadata)
        metadata.each_with_object({}) { |(k, v), out| out[k.to_s] = v }
      end

      def deep_dup_attrs(attrs)
        attrs.each_with_object({}) do |(k, v), out|
          out[k.to_s] = v.is_a?(Hash) ? stringify_meta(v) : v
        end
      end
    end
  end
end
