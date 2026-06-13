# frozen_string_literal: true

module Smplkit
  module Config
    # Type of a +ConfigItem+ value.
    module ItemType
      BOOLEAN = "BOOLEAN"
      JSON = "JSON"
      NUMBER = "NUMBER"
      STRING = "STRING"

      ALL = [BOOLEAN, JSON, NUMBER, STRING].freeze
    end

    # A single typed item in a +Config+.
    class ConfigItem
      attr_accessor :name, :value, :type, :description

      # Create a typed config item.
      #
      # @param name [String] The item key within its config.
      # @param value [Object] The item's value.
      # @param type [String] The item value type — one of +"STRING"+,
      #   +"NUMBER"+, +"BOOLEAN"+, or +"JSON"+.
      # @param description [String, nil] Optional human-readable description.
      def initialize(name:, value:, type:, description: nil)
        @name = name
        @value = value
        @type = type
        @description = description
      end

      # @return [Hash{String => Object}] The item as a plain Hash, omitting a
      #   +nil+ description.
      def to_h
        { "name" => @name, "value" => @value, "type" => @type, "description" => @description }.compact
      end

      def ==(other)
        other.is_a?(ConfigItem) && other.name == @name && other.value == @value &&
          other.type == @type && other.description == @description
      end
      alias eql? ==

      def hash = [@name, @value, @type, @description].hash
    end

    # Per-environment value overrides for a +Config+.
    #
    # Read-only inspection container. Mutation is performed via +Config+'s
    # setters with +environment:+ (e.g.
    # +cfg.set_string("k", "v", environment: "production")+).
    #
    # An override stores only the raw value; the declared type and description
    # come from the base item, so an item's type and description are ignored
    # when an environment override is supplied.
    class ConfigEnvironment
      # @param values [Hash{String => Object}, nil] Initial overrides as a flat
      #   +{key => raw_value}+ map. A legacy +{key => {"value" => raw}}+ wrapper
      #   is unwrapped to the raw value.
      def initialize(values: nil)
        @values_raw = {}
        return unless values

        values.each do |k, v|
          # Tolerate a legacy +{ "value" => raw, "type" => t }+ wrapper in
          # case a caller passes the old shape; unwrap to the raw value.
          @values_raw[k] = v.is_a?(Hash) && v.key?("value") ? v["value"] : v
        end
      end

      # Returns overrides as a plain Hash +{ "key" => raw_value }+.
      #
      # @return [Hash{String => Object}] A read-only shallow copy of the
      #   overrides.
      def values
        @values_raw.dup
      end

      # Returns overrides as a plain Hash +{ "key" => raw_value }+. Retained
      # as a separate accessor for backward compatibility; identical to
      # +values+ now that env overrides are stored flat.
      #
      # @return [Hash{String => Object}] A read-only shallow copy of the
      #   overrides.
      def values_raw
        @values_raw.dup
      end

      def _replace_raw(values)
        @values_raw = values
      end
    end

    # A configuration resource — a typed bag of items with per-environment
    # overrides.
    #
    # Provides management operations (save, set_string/set_number/...) and
    # runtime evaluation via +get+ on the parent +ConfigClient+.
    class Config
      attr_accessor :id, :key, :name, :description, :parent_id, :created_at, :updated_at

      # @param client [ConfigClient, nil] The owning client, or +nil+ for a
      #   detached model that cannot save or delete.
      # @param key [String] The config identifier (slug).
      # @param id [String, nil] The server-assigned id, or +nil+ for an unsaved
      #   config.
      # @param name [String, nil] Display name.
      # @param description [String, nil] Optional description.
      # @param parent_id [String, nil] Parent config id (slug), or +nil+ for a
      #   root config.
      # @param items [Array<ConfigItem>, nil] Base items.
      # @param environments [Hash{String => ConfigEnvironment}, nil]
      #   Per-environment overrides keyed by environment id.
      # @param created_at [Object, nil] Creation timestamp.
      # @param updated_at [Object, nil] Last-modified timestamp.
      def initialize(client = nil, key:, id: nil, name: nil, description: nil,
                     parent_id: nil, items: nil, environments: nil,
                     created_at: nil, updated_at: nil)
        @client = client
        @id = id
        @key = key
        @name = name
        @description = description
        @parent_id = parent_id
        @items = items ? items.dup : []
        @environments = environments ? environments.dup : {}
        @created_at = created_at
        @updated_at = updated_at
      end

      # @return [Array<ConfigItem>] A read-only shallow copy of the base items.
      def items
        @items.dup
      end

      # @return [Hash{String => ConfigEnvironment}] A read-only shallow copy of
      #   the per-environment overrides keyed by environment id.
      def environments
        @environments.dup
      end

      # Persist this config to the server. Creates a new config if unsaved, or
      # updates the existing one.
      #
      # @return [self]
      # @raise [Smplkit::NotFoundError] If the config no longer exists
      #   (update).
      # @raise [Smplkit::ValidationError] If the server rejects the request.
      # @raise [RuntimeError] If the model was constructed without a client.
      def save
        raise "Config was constructed without a client; cannot save" if @client.nil?

        updated =
          if @created_at.nil?
            @client._create_config(self)
          else
            @client._update_config(self)
          end
        _apply(updated)
        self
      end
      alias save! save

      # Delete this config from the server.
      #
      # @return [void]
      # @raise [RuntimeError] If the model was constructed without a client.
      def delete
        raise "Config was constructed without a client; cannot delete" if @client.nil?

        @client.delete(@key)
      end
      alias delete! delete

      # Set (or replace) an item. When +environment:+ is given, sets an
      # override on that environment.
      #
      # An environment override stores only the raw value; the declared type and
      # description come from the base item, so the +ConfigItem+'s type and
      # description are ignored when +environment:+ is supplied.
      #
      # @param item [ConfigItem] The item to set; its +name+ is the item key.
      # @param environment [String, nil] When given, set the value as an
      #   override on this environment rather than on the base config.
      # @return [self]
      def set(item, environment: nil)
        set_typed(item.name, item.value, item.type, environment: environment, description: item.description)
      end

      # Convenience: set a STRING item (or environment override).
      #
      # @param name [String] The item key to set.
      # @param value [String] The string value.
      # @param environment [String, nil] When given, set the value as an
      #   override on this environment rather than on the base config.
      # @param description [String, nil] Optional human-readable description.
      #   Ignored when setting an environment override.
      # @return [self]
      def set_string(name, value, environment: nil, description: nil)
        set_typed(name, value, ItemType::STRING, environment: environment, description: description)
      end

      # Convenience: set a NUMBER item (or environment override).
      #
      # @param name [String] The item key to set.
      # @param value [Integer, Float] The numeric value.
      # @param environment [String, nil] When given, set the value as an
      #   override on this environment rather than on the base config.
      # @param description [String, nil] Optional human-readable description.
      #   Ignored when setting an environment override.
      # @return [self]
      def set_number(name, value, environment: nil, description: nil)
        set_typed(name, value, ItemType::NUMBER, environment: environment, description: description)
      end

      # Convenience: set a BOOLEAN item (or environment override).
      #
      # @param name [String] The item key to set.
      # @param value [Boolean] The boolean value.
      # @param environment [String, nil] When given, set the value as an
      #   override on this environment rather than on the base config.
      # @param description [String, nil] Optional human-readable description.
      #   Ignored when setting an environment override.
      # @return [self]
      def set_boolean(name, value, environment: nil, description: nil)
        set_typed(name, value, ItemType::BOOLEAN, environment: environment, description: description)
      end

      # Convenience: set a JSON item (or environment override).
      #
      # @param name [String] The item key to set.
      # @param value [Object] Any JSON-serializable value (Hash, Array, or
      #   primitive).
      # @param environment [String, nil] When given, set the value as an
      #   override on this environment rather than on the base config.
      # @param description [String, nil] Optional human-readable description.
      #   Ignored when setting an environment override.
      # @return [self]
      def set_json(name, value, environment: nil, description: nil)
        set_typed(name, value, ItemType::JSON, environment: environment, description: description)
      end

      # Remove an item by name. When +environment:+ is given, removes the
      # per-environment override only. Removing an item that isn't present is a
      # no-op.
      #
      # @param name [String] The item key to remove.
      # @param environment [String, nil] When given, remove only this
      #   environment's override for +name+, leaving the base item intact.
      # @return [self]
      def remove(name, environment: nil)
        if environment
          env = @environments[environment]
          return self unless env

          raw = env.values_raw
          raw.delete(name)
          env._replace_raw(raw)
        else
          @items.reject! { |i| i.name == name }
        end
        self
      end

      def _apply(other)
        @id = other.id
        @key = other.key
        @name = other.name
        @description = other.description
        @parent_id = other.parent_id
        @items = other.items
        @environments = other.environments
        @created_at = other.created_at
        @updated_at = other.updated_at
      end

      private

      def set_typed(name, value, type, environment:, description: nil)
        if environment.nil?
          existing = @items.find { |i| i.name == name }
          if existing
            existing.value = value
            existing.type = type
            existing.description = description if description
          else
            @items << ConfigItem.new(name: name, value: value, type: type, description: description)
          end
        else
          # Env overrides carry the raw value only — type and description live
          # on the base item, not on the override.
          env = (@environments[environment] ||= ConfigEnvironment.new)
          raw = env.values_raw
          raw[name] = value
          env._replace_raw(raw)
        end
        self
      end
    end
  end

  # Top-level re-exports.
  ConfigItem = Config::ConfigItem
  ConfigEnvironment = Config::ConfigEnvironment
  ItemType = Config::ItemType
end
