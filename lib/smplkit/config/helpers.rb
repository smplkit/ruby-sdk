# frozen_string_literal: true

module Smplkit
  module Config
    module Helpers
      module_function

      # Translate a JSON:API resource Hash into a Config domain model.
      def config_from_json(client, resource)
        attrs = resource["attributes"] || {}
        items = (attrs["items"] || {}).map do |name, item|
          if item.is_a?(Hash) && item.key?("value")
            ConfigItem.new(
              name: name,
              value: item["value"],
              type: item["type"],
              description: item["description"]
            )
          else
            ConfigItem.new(name: name, value: item, type: ItemType::JSON)
          end
        end

        environments = (attrs["environments"] || {}).each_with_object({}) do |(env, env_data), out|
          env_values = env_data.is_a?(Hash) ? (env_data["values"] || {}) : {}
          out[env] = ConfigEnvironment.new(values: env_values)
        end

        Config.new(
          client,
          id: resource["id"] || attrs["id"],
          key: attrs["key"] || resource["id"],
          name: attrs["name"],
          description: attrs["description"],
          parent_id: attrs["parent"] || attrs["parent_id"],
          items: items,
          environments: environments,
          created_at: attrs["created_at"],
          updated_at: attrs["updated_at"]
        )
      end

      def build_config_request_body(config)
        items = {}
        config.items.each do |item|
          items[item.name] = {
            "value" => item.value,
            "type" => item.type,
            "description" => item.description
          }.compact
        end

        environments = config.environments.each_with_object({}) do |(env, env_obj), out|
          out[env] = { "values" => env_obj.values_raw }
        end

        # The Config schema (per the OpenAPI spec) does not include +key+ in
        # attributes — the resource +id+ carries the customer-facing key.
        attributes = {
          "name" => config.name,
          "description" => config.description,
          "parent" => config.parent_id,
          "items" => items,
          "environments" => environments
        }.compact
        { "data" => { "type" => "config", "id" => config.key, "attributes" => attributes } }
      end

      # Deep-merge two Hashes, with +override+ winning. Mirrors the Python
      # +deep_merge+ helper used by the resolver.
      def deep_merge(base, override)
        result = base.dup
        override.each do |key, value|
          result[key] = if result[key].is_a?(Hash) && value.is_a?(Hash)
                          deep_merge(result[key], value)
                        else
                          value
                        end
        end
        result
      end

      # Unwrap typed items +{ key => { value, type, desc } }+ to +{ key => raw }+.
      def unwrap_items(items)
        items.each_with_object({}) do |(k, v), out|
          out[k] = v.is_a?(Hash) && v.key?("value") ? v["value"] : v
        end
      end

      # Resolve the full configuration for an environment given a config chain.
      #
      # Walks from root (last element) to child (first element), accumulating
      # values via deep merge so child configs override parent configs.
      def resolve_chain(chain, environment)
        accumulated = {}
        chain.reverse_each do |config_data|
          raw_items = config_data["items"] || config_data["values"] || {}
          base_values = unwrap_items(raw_items)
          env_data = (config_data["environments"] || {})[environment] || {}
          env_raw = env_data.is_a?(Hash) ? (env_data["values"] || {}) : {}
          env_values = unwrap_items(env_raw)
          config_resolved = deep_merge(base_values, env_values)
          accumulated = deep_merge(accumulated, config_resolved)
        end
        accumulated
      end
    end
  end
end
