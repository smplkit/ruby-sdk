# frozen_string_literal: true

module Smplkit
  module Logging
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
    class SmplLogger
      attr_accessor :id, :name, :resolved_level, :level, :service, :environment,
                    :log_group_id, :managed, :created_at, :updated_at, :description

      def initialize(client = nil, name:, resolved_level:, id: nil, level: nil,
                     service: nil, environment: nil, log_group_id: nil,
                     managed: true, description: nil, created_at: nil, updated_at: nil)
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
        @created_at = created_at
        @updated_at = updated_at
      end

      def managed? = !!@managed

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
