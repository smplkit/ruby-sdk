# frozen_string_literal: true

module Smplkit
  module Flags
    # A constrained value entry on a +Flag+.
    #
    # Lives in +Flag#values+. Frozen — author values via +Flag#add_value+ /
    # +Flag#remove_value+ / +Flag#clear_values+.
    FlagValue = Struct.new(:name, :value, keyword_init: true)

    # A single targeting rule on a +Flag+.
    #
    # Lives in +FlagEnvironment#rules+. Frozen — author rules via the
    # +Smplkit::Rule+ fluent builder and pass through +Flag#add_rule+.
    #
    # Attributes:
    #   - logic: JSON Logic predicate. Empty Hash means "always match".
    #   - value: Value to serve when +logic+ evaluates truthy.
    #   - description: Human-readable label (optional).
    class FlagRule
      attr_reader :logic, :value, :description

      def initialize(logic:, value: nil, description: nil)
        @logic = logic
        @value = value
        @description = description
        freeze
      end

      def ==(other)
        other.is_a?(FlagRule) && logic == other.logic && value == other.value && description == other.description
      end
      alias eql? ==

      def hash = [logic, value, description].hash
    end

    # Per-environment configuration on a +Flag+.
    #
    # Lives at +flag.environments[env_name]+. Frozen — mutate via +Flag#add_rule+
    # / +Flag#enable_rules+ / +Flag#disable_rules+ / +Flag#set_default+ /
    # +Flag#clear_rules+ (with +environment:+).
    #
    # Attributes:
    #   - enabled: Whether the flag is active in this environment.
    #   - default: Environment-specific default override (+nil+ means no override).
    #   - rules: Targeting rules to evaluate, in order.
    class FlagEnvironment
      attr_reader :enabled, :default, :rules

      def initialize(enabled: true, default: nil, rules: [])
        @enabled = enabled
        @default = default
        @rules = rules.is_a?(Array) ? rules.dup.freeze : rules
        freeze
      end

      def enabled? = @enabled

      # Return a new FlagEnvironment with the given fields replaced.
      def with(**changes)
        self.class.new(
          enabled: changes.fetch(:enabled, @enabled),
          default: changes.fetch(:default, @default),
          rules: changes.fetch(:rules, @rules)
        )
      end

      def ==(other)
        other.is_a?(FlagEnvironment) && enabled == other.enabled && default == other.default && rules == other.rules
      end
      alias eql? ==

      def hash = [enabled, default, rules].hash
    end

    # A flag resource.
    #
    # Provides management operations (save, add_rule, environment settings)
    # and runtime evaluation via +get+.
    #
    # Use typed variants (BooleanFlag, StringFlag, NumberFlag, JsonFlag)
    # for type-safe +get+ return values.
    class Flag
      attr_accessor :id, :name, :type, :default, :description, :created_at, :updated_at

      def initialize(client = nil, name:, type:, default:, id: nil, values: nil,
                     description: nil, environments: nil, created_at: nil, updated_at: nil)
        @client = client
        @id = id
        @name = name
        @type = type
        @default = default
        @values = values&.dup
        @description = description
        @environments = environments ? environments.dup : {}
        @created_at = created_at
        @updated_at = updated_at
      end

      # Read-only view of constrained values. +nil+ means unconstrained.
      #
      # Mutate via +add_value+ / +remove_value+ / +clear_values+.
      #
      # @return [Array<FlagValue>, nil] the constrained values, or +nil+ when
      #   the flag is unconstrained.
      def values
        @values&.dup
      end

      # Read-only view of per-environment configuration.
      #
      # Mutate via +add_rule+ / +enable_rules+ / +disable_rules+ /
      # +set_default+ (with +environment:+) / +clear_rules+.
      #
      # @return [Hash{String => FlagEnvironment}] the per-environment configuration.
      def environments
        @environments.dup
      end

      # Persist this flag to the server.
      #
      # Creates a new flag if unsaved, or updates the existing one. Requires a
      # client (i.e. the flag was constructed via +client.flags.new_*+ or
      # returned from +client.flags.get+ / +client.flags.list+).
      #
      # @return [self] this flag, with server-assigned fields applied.
      def save
        raise "Flag was constructed without a client; cannot save" if @client.nil?

        updated =
          if @created_at.nil?
            @client._create_flag(self)
          else
            @client._update_flag(self)
          end
        _apply(updated)
        self
      end
      alias save! save

      # Delete this flag from the server.
      #
      # @return [void]
      # @raise [Smplkit::NotFoundError] no flag with this id exists for the account.
      def delete
        raise "Flag was constructed without a client or id; cannot delete" if @client.nil? || @id.nil?

        @client.delete(@id)
      end
      alias delete! delete

      # Append a rule to a specific environment.
      #
      # The +built_rule+ Hash must include an +"environment"+ key.
      # Call +save+ to persist.
      #
      # @param built_rule [Hash] the Hash produced by
      #   +Smplkit::Rule.new(..., environment: ...).when(...).serve(...)+; must
      #   include an +"environment"+ key naming the target environment.
      # @return [self] this flag, so calls can be chained.
      # @raise [ArgumentError] the +built_rule+ Hash has no +"environment"+ key.
      def add_rule(built_rule)
        env_key = built_rule["environment"]
        if env_key.nil?
          raise ArgumentError,
                "Built rule must include 'environment' key. " \
                "Use Smplkit::Rule.new(..., environment: 'env_key').when(...).serve(...)"
        end

        flag_rule = FlagRule.new(
          logic: (built_rule["logic"] || {}).dup,
          value: built_rule["value"],
          description: built_rule["description"]
        )
        existing = @environments[env_key] || FlagEnvironment.new
        @environments[env_key] = existing.with(rules: (existing.rules + [flag_rule]).freeze)
        self
      end

      # Enable rule evaluation. Call +save+ to persist.
      #
      # @param environment [String, nil] name of the environment to enable; when
      #   +nil+ (the default), enables rules in every environment configured on
      #   this flag.
      # @return [self] this flag, so calls can be chained.
      def enable_rules(environment: nil)
        scoped(environment) { |k| @environments[k] = (@environments[k] || FlagEnvironment.new).with(enabled: true) }
        self
      end

      # Disable rule evaluation (kill switch). Call +save+ to persist.
      #
      # When disabled, +get+ skips rules and returns the env-specific default
      # (or the flag's base default).
      #
      # @param environment [String, nil] name of the environment to disable; when
      #   +nil+ (the default), disables rules in every environment configured on
      #   this flag.
      # @return [self] this flag, so calls can be chained.
      def disable_rules(environment: nil)
        scoped(environment) { |k| @environments[k] = (@environments[k] || FlagEnvironment.new).with(enabled: false) }
        self
      end

      # Remove rules. Call +save+ to persist.
      #
      # @param environment [String, nil] name of the environment whose rules to
      #   remove; when +nil+ (the default), removes rules from every environment
      #   configured on this flag.
      # @return [self] this flag, so calls can be chained.
      def clear_rules(environment: nil)
        scoped(environment) do |k|
          @environments[k] = (@environments[k] || FlagEnvironment.new).with(rules: [].freeze)
        end
        self
      end

      # Set the flag's per-environment default served value. Call +save+ to persist.
      #
      # @param value [Object] the default value to serve when no rule matches.
      # @param environment [String] name of the environment whose default to set.
      # @return [self] this flag, so calls can be chained.
      def set_default(value, environment:)
        @environments[environment] = (@environments[environment] || FlagEnvironment.new).with(default: value)
        self
      end

      # Clear the per-environment default override on +environment+.
      #
      # After clearing, the environment falls back to the flag's base default
      # when no rule matches. Call +save+ to persist.
      #
      # @param environment [String] name of the environment whose default
      #   override to clear.
      # @return [self] this flag, so calls can be chained.
      def clear_default(environment:)
        @environments[environment] = (@environments[environment] || FlagEnvironment.new).with(default: nil)
        self
      end

      # Append a constrained value to the flag's values list. Call +save+ to persist.
      #
      # @param flag_value [FlagValue] the value entry to allow the flag to serve.
      # @return [self] this flag, so calls can be chained.
      def add_value(flag_value)
        @values ||= []
        @values << flag_value
        self
      end

      # Remove the first values entry whose +name+ matches.
      #
      # @param name [String] the value-entry name to remove; the first match is
      #   removed and others are left in place.
      # @return [self] this flag, so calls can be chained.
      def remove_value(name)
        return self unless @values

        @values = @values.reject { |v| v.name == name }
        self
      end

      # Clear the constrained values list (unconstrained). Call +save+ to persist.
      #
      # @return [self] this flag, so calls can be chained.
      def clear_values
        @values = []
        self
      end

      def _apply(other)
        @id = other.id
        @name = other.name
        @type = other.type
        @default = other.default
        @description = other.description
        @values = other.instance_variable_get(:@values)&.dup
        @environments = other.instance_variable_get(:@environments).dup
        @created_at = other.created_at
        @updated_at = other.updated_at
      end

      private

      def scoped(environment, &)
        if environment.nil?
          @environments.each_key(&)
        else
          yield(environment)
        end
      end
    end

    class BooleanFlag < Flag
      # Evaluate this flag and return its current boolean value.
      #
      # @param context [Array<Smplkit::Context>, nil] optional entities to
      #   evaluate targeting rules against; when omitted the ambient request
      #   context (if any) is used.
      # @return [Boolean] the evaluated boolean value, or this flag's default
      #   when no environment override or rule applies (or the evaluated value
      #   is not a boolean).
      def get(context: nil)
        value = @client._evaluate_handle(@id, @default, context)
        [true, false].include?(value) ? value : @default
      end
    end

    class StringFlag < Flag
      # Evaluate this flag and return its current string value.
      #
      # @param context [Array<Smplkit::Context>, nil] optional entities to
      #   evaluate targeting rules against; when omitted the ambient request
      #   context (if any) is used.
      # @return [String] the evaluated string value, or this flag's default
      #   when no environment override or rule applies (or the evaluated value
      #   is not a String).
      def get(context: nil)
        value = @client._evaluate_handle(@id, @default, context)
        value.is_a?(String) ? value : @default
      end
    end

    class NumberFlag < Flag
      # Evaluate this flag and return its current numeric value.
      #
      # @param context [Array<Smplkit::Context>, nil] optional entities to
      #   evaluate targeting rules against; when omitted the ambient request
      #   context (if any) is used.
      # @return [Numeric] the evaluated numeric value, or this flag's default
      #   when no environment override or rule applies (or the evaluated value
      #   is not a Numeric).
      def get(context: nil)
        value = @client._evaluate_handle(@id, @default, context)
        value.is_a?(Numeric) ? value : @default
      end
    end

    class JsonFlag < Flag
      # Evaluate this flag and return its current JSON value.
      #
      # @param context [Array<Smplkit::Context>, nil] optional entities to
      #   evaluate targeting rules against; when omitted the ambient request
      #   context (if any) is used.
      # @return [Hash] the evaluated JSON object, or this flag's default when no
      #   environment override or rule applies (or the evaluated value is not a
      #   Hash).
      def get(context: nil)
        value = @client._evaluate_handle(@id, @default, context)
        value.is_a?(Hash) ? value : @default
      end
    end
  end

  # Top-level re-exports for convenience.
  FlagValue = Flags::FlagValue
  FlagRule = Flags::FlagRule
  FlagEnvironment = Flags::FlagEnvironment
end
