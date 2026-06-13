# frozen_string_literal: true

require "set"

module Smplkit
  module Logging
    # Client-side level resolution.
    #
    # The server stores raw configuration and returns it as-is; the SDK is
    # responsible for walking the inheritance chain.
    #
    # @api private
    module Resolution
      FALLBACK_LEVEL = "INFO"

      module_function

      # Resolve the effective level for +logger_id+ in +environment+.
      #
      # Resolution chain (first non-nil wins):
      #
      #   1. Logger's own +environments[env].level+
      #   2. Logger's own +level+
      #   3. Group chain (recursive: group env level → group level → parent group …)
      #   4. Dot-notation ancestry (+com.acme.payments+ → +com.acme+ → +com+,
      #      applying steps 1–3 at each)
      #   5. System fallback: +"INFO"+
      #
      # +loggers+ and +groups+ are id-keyed Hashes whose values are Hashes
      # with the same shape as the Python SDK: +"level"+, +"group"+ (parent
      # group id for loggers; parent_id for groups), +"environments"+
      # (Hash keyed by env name with +{"level" => "..."}+ values).
      def resolve_level(logger_id, environment, loggers, groups)
        result = resolve_for_entry(logger_id, environment, loggers, groups)
        if result
          if Smplkit::Debug.enabled
            source = find_resolution_source(logger_id, environment, loggers, groups)
            Smplkit.debug("resolution", "#{logger_id} -> #{result} (source: #{source})")
          end
          return result
        end

        parts = logger_id.split(".")
        (parts.length - 1).downto(1) do |i|
          ancestor_id = parts[0, i].join(".")
          result = resolve_for_entry(ancestor_id, environment, loggers, groups)
          if result
            Smplkit.debug("resolution", "#{logger_id} -> #{result} (source: ancestor \"#{ancestor_id}\")")
            return result
          end
        end

        Smplkit.debug("resolution", "#{logger_id} -> #{FALLBACK_LEVEL} (source: system default)")
        FALLBACK_LEVEL
      end

      # Try to resolve a level for a single entry (logger or ancestor).
      # Returns +nil+ if no level is found at any step of 1–3.
      def resolve_for_entry(logger_id, environment, loggers, groups)
        entry = loggers[logger_id]
        return nil if entry.nil?

        env_level = env_level_of(entry, environment)
        return env_level if env_level

        base = entry["level"]
        return base if base

        resolve_group_chain(entry["group"], environment, groups)
      end

      # Walk the group chain looking for a level. Cycle-safe via +visited+.
      def resolve_group_chain(group_id, environment, groups)
        visited = Set.new
        current_id = group_id
        while !current_id.nil? && !visited.include?(current_id)
          visited.add(current_id)
          group = groups[current_id]
          break if group.nil?

          env_level = env_level_of(group, environment)
          return env_level if env_level

          base = group["level"]
          return base if base

          current_id = group["group"]
        end
        nil
      end

      # Human-readable label for which resolution step won. Only consulted
      # when debug logging is enabled; mirrors Python's +_find_resolution_source+.
      def find_resolution_source(logger_id, environment, loggers, groups)
        entry = loggers[logger_id]
        return "not found" if entry.nil?

        return %(env override "#{environment}") if env_level_of(entry, environment)
        return "base level" if entry["level"]

        group_id = entry["group"]
        return %(group "#{group_id}") if resolve_group_chain(group_id, environment, groups)

        "unknown"
      end

      def env_level_of(entry, environment)
        envs = entry["environments"]
        return nil unless envs.is_a?(Hash)

        env_data = envs[environment]
        return nil unless env_data.is_a?(Hash)

        env_data["level"]
      end
    end
  end
end
