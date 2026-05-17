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

      def initialize(name:, value:, type:, description: nil)
        @name = name
        @value = value
        @type = type
        @description = description
      end

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
    class ConfigEnvironment
      def initialize(values: nil)
        @values_raw = {}
        return unless values

        values.each do |k, v|
          @values_raw[k] = v.is_a?(Hash) && v.key?("value") ? v : { "value" => v }
        end
      end

      # Returns overrides as a plain Hash +{ "key" => raw_value }+.
      def values
        @values_raw.transform_values { |v| v["value"] }
      end

      # Returns the full typed overrides
      # +{ "key" => { "value" => v, "type" => t, "description" => d } }+
      # (read-only deep copy).
      def values_raw
        @values_raw.transform_values { |v| v.is_a?(Hash) ? v.dup : v }
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

      def items
        @items.dup
      end

      def environments
        @environments.dup
      end

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

      def delete
        raise "Config was constructed without a client; cannot delete" if @client.nil?

        @client.delete(@key)
      end
      alias delete! delete

      def set_string(name, value, environment: nil, description: nil)
        set_typed(name, value, ItemType::STRING, environment: environment, description: description)
      end

      def set_number(name, value, environment: nil, description: nil)
        set_typed(name, value, ItemType::NUMBER, environment: environment, description: description)
      end

      def set_boolean(name, value, environment: nil, description: nil)
        set_typed(name, value, ItemType::BOOLEAN, environment: environment, description: description)
      end

      def set_json(name, value, environment: nil, description: nil)
        set_typed(name, value, ItemType::JSON, environment: environment, description: description)
      end

      def remove_item(name, environment: nil)
        if environment
          env = @environments[environment]
          return unless env

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
          env = (@environments[environment] ||= ConfigEnvironment.new)
          raw = env.values_raw
          raw[name] = { "value" => value, "type" => type, "description" => description }.compact
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
