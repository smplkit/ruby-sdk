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
    end
  end
end
