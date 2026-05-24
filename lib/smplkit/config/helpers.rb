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
          # Per ADR-024 §2.4 env_data is already the flat override map
          # +{key: rawValue}+ — the old +{values: {...}}+ envelope is gone.
          env_values = env_data.is_a?(Hash) ? env_data : {}
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

      # Build the parent chain (child-first, root-last) for a +Config+,
      # walking +parent_id+ pointers across the +by_id+ map. Mirrors the
      # Python SDK's client-side chain construction.
      def build_chain(target, by_id)
        chain = []
        current = target
        loop do
          chain << config_to_chain_entry(current)
          parent_id = current.parent_id
          break if parent_id.nil? || parent_id == ""

          parent = by_id[parent_id]
          break unless parent

          current = parent
        end
        chain
      end

      # Build a single chain entry (the +id+/+items+/+environments+ Hash
      # shape used by +resolve_chain+) from a +Config+ domain model.
      def config_to_chain_entry(config)
        items_hash = config.items.to_h do |item|
          [item.name,
           { "value" => item.value, "type" => item.type, "description" => item.description }.compact]
        end
        environments = config.environments.each_with_object({}) do |(env_key, env_obj), out|
          # Per ADR-024 §2.4 env entries are flat +{key: rawValue}+ maps —
          # no +values+ envelope, no per-key type wrapper.
          out[env_key] = env_obj.values
        end
        { "id" => config.id, "items" => items_hash, "environments" => environments }
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
          # Per ADR-024 §2.4 env entries are flat +{key: rawValue}+ maps —
          # the resolver reads the env entry directly as the override map.
          env_data = (config_data["environments"] || {})[environment] || {}
          env_values = env_data.is_a?(Hash) ? env_data : {}
          config_resolved = deep_merge(base_values, env_values)
          accumulated = deep_merge(accumulated, config_resolved)
        end
        accumulated
      end
    end
  end
end
