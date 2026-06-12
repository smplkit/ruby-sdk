# frozen_string_literal: true

module Smplkit
  module Platform
    # Accept Color, hex string, or nil; reject anything else.
    def self.coerce_color(value)
      return value if value.nil? || value.is_a?(Color)
      return Color.new(value) if value.is_a?(String)

      raise TypeError, "color must be a Color, hex string, or nil; got #{value.class}: #{value.inspect}"
    end

    # Environment resource (sync). Mutate fields, then call +save+.
    class Environment
      attr_accessor :id, :name, :classification, :created_at, :updated_at
      attr_reader :color

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

      def color=(value)
        @color = Platform.coerce_color(value)
      end

      # Create or update this environment on the server.
      def save
        raise "Environment was constructed without a client; cannot save" if @client.nil?

        other = @created_at.nil? ? @client._create(self) : @client._update(self)
        _apply(other)
        self
      end
      alias save! save

      # Delete this environment from the server.
      def delete
        raise "Environment was constructed without a client or id; cannot delete" if @client.nil? || @id.nil?

        @client.delete(@id)
      end
      alias delete! delete

      def to_s
        "Environment(id=#{@id.inspect}, name=#{@name.inspect}, classification=#{@classification.inspect})"
      end
      alias inspect to_s

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

      def initialize(client = nil, name:, id: nil, created_at: nil, updated_at: nil)
        @client = client
        @id = id
        @name = name
        @created_at = created_at
        @updated_at = updated_at
      end

      # Create or update this service on the server.
      def save
        raise "Service was constructed without a client; cannot save" if @client.nil?

        other = @created_at.nil? ? @client._create(self) : @client._update(self)
        _apply(other)
        self
      end
      alias save! save

      # Delete this service from the server.
      def delete
        raise "Service was constructed without a client or id; cannot delete" if @client.nil? || @id.nil?

        @client.delete(@id)
      end
      alias delete! delete

      def to_s
        "Service(id=#{@id.inspect}, name=#{@name.inspect})"
      end
      alias inspect to_s

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

      def initialize(client = nil, name:, id: nil, attributes: nil, created_at: nil, updated_at: nil)
        @client = client
        @id = id
        @name = name
        @attributes = attributes ? deep_dup_attrs(attributes) : {}
        @created_at = created_at
        @updated_at = updated_at
      end

      # Add a known-attribute slot. Local; call +save+ to persist.
      def add_attribute(name, **metadata)
        @attributes[name] = stringify_meta(metadata)
      end

      # Remove a known-attribute slot. Local; call +save+ to persist.
      def remove_attribute(name)
        @attributes.delete(name)
      end

      # Replace a known-attribute slot's metadata. Local; call +save+.
      def update_attribute(name, **metadata)
        @attributes[name] = stringify_meta(metadata)
      end

      # Create or update this context type on the server.
      def save
        raise "ContextType was constructed without a client; cannot save" if @client.nil?

        other = @created_at.nil? ? @client._create(self) : @client._update(self)
        _apply(other)
        self
      end
      alias save! save

      # Delete this context type from the server.
      def delete
        raise "ContextType was constructed without a client or id; cannot delete" if @client.nil? || @id.nil?

        @client.delete(@id)
      end
      alias delete! delete

      def to_s
        "ContextType(id=#{@id.inspect}, name=#{@name.inspect})"
      end
      alias inspect to_s

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
