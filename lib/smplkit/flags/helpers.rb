# frozen_string_literal: true

module Smplkit
  module Flags
    # Helpers that translate between server JSON and the SDK's wrapper model
    # objects.
    module Helpers
      module_function

      # Translate a JSON:API resource Hash into a flat dict the runtime cache
      # can consume. The shape mirrors +smplkit.flags.helpers._flag_dict_from_json+
      # in the Python SDK.
      def flag_dict_from_json(resource)
        attrs = resource["attributes"] || {}
        environments = (attrs["environments"] || {}).each_with_object({}) do |(env_key, env_data), out|
          out[env_key] = parse_env(env_data || {})
        end

        {
          "id" => resource["id"] || attrs["id"],
          "name" => attrs["name"],
          "type" => attrs["type"],
          "default" => attrs["default"],
          "values" => parse_values(attrs["values"]),
          "description" => attrs["description"],
          "environments" => environments
        }
      end

      def parse_values(raw)
        return nil if raw.nil?

        raw.map { |v| FlagValue.new(name: v["name"], value: v["value"]) }
      end

      def parse_env(env_data)
        rules = (env_data["rules"] || []).map do |r|
          FlagRule.new(
            logic: r["logic"] || {},
            value: r["value"],
            description: r["description"]
          )
        end
        FlagEnvironment.new(
          enabled: env_data.fetch("enabled", true) ? true : false,
          default: env_data["default"],
          rules: rules
        )
      end
    end
  end
end
