# frozen_string_literal: true

module Smplkit
  module Logging
    module Helpers
      module_function

      def logger_resource_to_model(client, resource)
        attrs = resource["attributes"] || {}
        SmplLogger.new(
          client,
          id: resource["id"] || attrs["id"],
          name: attrs["name"],
          resolved_level: attrs["resolved_level"] && LogLevel.coerce(attrs["resolved_level"]),
          level: attrs["level"] && LogLevel.coerce(attrs["level"]),
          service: attrs["service"],
          environment: attrs["environment"],
          log_group_id: attrs["log_group_id"],
          managed: attrs.fetch("managed", true),
          description: attrs["description"],
          created_at: attrs["created_at"],
          updated_at: attrs["updated_at"]
        )
      end

      def log_group_resource_to_model(client, resource)
        attrs = resource["attributes"] || {}
        SmplLogGroup.new(
          client,
          id: resource["id"] || attrs["id"],
          key: attrs["key"] || resource["id"],
          name: attrs["name"],
          level: attrs["level"] && LogLevel.coerce(attrs["level"]),
          description: attrs["description"],
          parent_id: attrs["parent_id"],
          environments: attrs["environments"] || {},
          created_at: attrs["created_at"],
          updated_at: attrs["updated_at"]
        )
      end

      def build_logger_body(logger)
        attributes = {
          "name" => logger.name,
          "resolved_level" => logger.resolved_level&.to_s,
          "level" => logger.level&.to_s,
          "service" => logger.service,
          "environment" => logger.environment,
          "log_group_id" => logger.log_group_id,
          "managed" => logger.managed,
          "description" => logger.description
        }.compact
        { "data" => { "type" => "logger", "id" => logger.id, "attributes" => attributes } }
      end

      def build_log_group_body(group)
        attributes = {
          "key" => group.key,
          "name" => group.name,
          "level" => group.level&.to_s,
          "description" => group.description,
          "parent_id" => group.parent_id,
          "environments" => group.environments
        }.compact
        { "data" => { "type" => "log_group", "id" => group.key, "attributes" => attributes } }
      end
    end
  end
end
