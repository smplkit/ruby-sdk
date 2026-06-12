# frozen_string_literal: true

module Smplkit
  module Logging
    # Per-environment configuration on a logger or log group.
    #
    # Lives at +logger.environments[env_name]+ (a +Hash{String => LoggerEnvironment}+).
    # Frozen — mutate the override via +logger.set_level(level, environment: "...")+
    # or remove it via +logger.clear_level(environment: "...")+.
    #
    # Attributes:
    #   - level: Per-environment level override (+nil+ means no override).
    LoggerEnvironment = Struct.new(:level, keyword_init: true) do
      def initialize(level: nil)
        super
        freeze
      end
    end

    # Coerce a dict input into +Hash{String => LoggerEnvironment}+.
    #
    # Accepts both pre-built +LoggerEnvironment+ instances and the wire-shaped
    # +{env_id => {"level" => "ERROR"}}+ dicts.
    def self.convert_environments(value)
      return {} if value.nil? || value.empty?

      value.each_with_object({}) do |(env_id, env_data), out|
        out[env_id] = build_logger_environment(env_data)
      end
    end

    def self.build_logger_environment(env_data)
      return env_data if env_data.is_a?(LoggerEnvironment)
      return LoggerEnvironment.new unless env_data.is_a?(Hash)

      level_str = env_data["level"] || env_data[:level]
      return LoggerEnvironment.new if level_str.nil?

      begin
        LoggerEnvironment.new(level: LogLevel.coerce(level_str))
      rescue ArgumentError
        LoggerEnvironment.new
      end
    end

    # Convert a typed environments dict to the wire-shaped dict for sending.
    # Entries with +level=nil+ are skipped (no override to send).
    def self.environments_to_wire(environments)
      environments.each_with_object({}) do |(env_id, env), out|
        out[env_id] = { "level" => env.level.to_s } unless env.level.nil?
      end
    end

    # A logger resource managed by the smplkit Logging service.
    #
    # Attributes:
    #   - id, name: identity
    #   - resolved_level: effective level computed by the platform from
    #     environment overrides + log group inheritance
    #   - level: explicit override (nil means inherit)
    #   - service, environment: provenance
    #   - log_group_id: parent log group, if any
    #   - managed: whether the SDK should apply server-driven level changes
    #   - environments: per-environment level overrides, keyed by environment
    class SmplLogger
      attr_accessor :id, :name, :resolved_level, :level, :service, :environment,
                    :log_group_id, :managed, :created_at, :updated_at, :description

      def initialize(client = nil, name:, resolved_level:, id: nil, level: nil,
                     service: nil, environment: nil, log_group_id: nil,
                     managed: true, description: nil, environments: nil,
                     created_at: nil, updated_at: nil)
        @client = client
        @id = id
        @name = name
        @resolved_level = resolved_level
        @level = level
        @service = service
        @environment = environment
        @log_group_id = log_group_id
        @managed = managed
        @description = description
        @environments = Logging.convert_environments(environments)
        @created_at = created_at
        @updated_at = updated_at
      end

      def managed? = !!@managed

      # Read-only view of per-environment level overrides. Mutate via
      # +set_level+ / +clear_level+ (with +environment: "..."+).
      def environments
        @environments.dup
      end

      # Set the log level.
      #
      # With +environment: nil+ (the default), sets the base log level used when
      # no environment-specific override applies. With +environment: "..."+,
      # sets the per-environment override. Changes are local until +save+.
      def set_level(level, environment: nil)
        if environment.nil?
          @level = level
        else
          @environments[environment] = LoggerEnvironment.new(level: level)
        end
      end

      # Remove a log level.
      #
      # With +environment: nil+ (the default), removes the base log level (the
      # logger then inherits from its group / ancestor / system default). With
      # +environment: "..."+, removes the per-environment override only. Changes
      # are local until +save+.
      def clear_level(environment: nil)
        if environment.nil?
          @level = nil
        else
          @environments.delete(environment)
        end
      end

      # Remove all per-environment level overrides.
      def clear_all_environment_levels
        @environments = {}
      end

      def save
        raise "SmplLogger was constructed without a client; cannot save" if @client.nil?

        updated = @client._update_logger(self)
        _apply(updated)
        self
      end
      alias save! save

      def delete
        raise "SmplLogger was constructed without a client; cannot delete" if @client.nil?

        @client.delete(@id || @name)
      end
      alias delete! delete

      def _apply(other)
        @id = other.id
        @name = other.name
        @resolved_level = other.resolved_level
        @level = other.level
        @service = other.service
        @environment = other.environment
        @log_group_id = other.log_group_id
        @managed = other.managed
        @description = other.description
        @environments = other.environments
        @created_at = other.created_at
        @updated_at = other.updated_at
      end
    end

    # A log group resource — a hierarchical bag of loggers with a shared
    # configured level.
    class SmplLogGroup
      attr_accessor :id, :key, :name, :level, :description, :parent_id, :environments,
                    :created_at, :updated_at

      def initialize(client = nil, key:, id: nil, name: nil, level: nil,
                     description: nil, parent_id: nil, environments: nil,
                     created_at: nil, updated_at: nil)
        @client = client
        @id = id
        @key = key
        @name = name
        @level = level
        @description = description
        @parent_id = parent_id
        @environments = environments || {}
        @created_at = created_at
        @updated_at = updated_at
      end

      def save
        raise "SmplLogGroup was constructed without a client; cannot save" if @client.nil?

        updated =
          if @created_at.nil?
            @client._create_log_group(self)
          else
            @client._update_log_group(self)
          end
        _apply(updated)
        self
      end
      alias save! save

      def delete
        raise "SmplLogGroup was constructed without a client; cannot delete" if @client.nil?

        @client.delete(@key)
      end
      alias delete! delete

      def _apply(other)
        @id = other.id
        @key = other.key
        @name = other.name
        @level = other.level
        @description = other.description
        @parent_id = other.parent_id
        @environments = other.environments
        @created_at = other.created_at
        @updated_at = other.updated_at
      end
    end
  end
end
