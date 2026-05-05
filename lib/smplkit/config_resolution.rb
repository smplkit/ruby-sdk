# frozen_string_literal: true

require_relative "errors"

module Smplkit
  # SDK configuration resolution: defaults -> file -> env vars -> constructor args.
  module ConfigResolution
    CONFIG_KEYS = {
      "api_key" => "SMPLKIT_API_KEY",
      "base_domain" => "SMPLKIT_BASE_DOMAIN",
      "scheme" => "SMPLKIT_SCHEME",
      "environment" => "SMPLKIT_ENVIRONMENT",
      "service" => "SMPLKIT_SERVICE",
      "debug" => "SMPLKIT_DEBUG",
      "telemetry" => "SMPLKIT_TELEMETRY"
    }.freeze

    BOOL_TRUE = %w[true 1 yes].freeze
    BOOL_FALSE = %w[false 0 no].freeze

    DEFAULTS = {
      "api_key" => nil,
      "base_domain" => "smplkit.com",
      "scheme" => "https",
      "environment" => nil,
      "service" => nil,
      "debug" => false,
      "telemetry" => true
    }.freeze

    ResolvedConfig = Struct.new(
      :api_key, :base_domain, :scheme, :environment, :service, :debug, :telemetry,
      keyword_init: true
    )

    ResolvedManagementConfig = Struct.new(
      :api_key, :base_domain, :scheme, :debug,
      keyword_init: true
    )

    module_function

    def parse_bool(value, key)
      lower = value.to_s.strip.downcase
      return true if BOOL_TRUE.include?(lower)
      return false if BOOL_FALSE.include?(lower)

      raise Error,
            "Invalid boolean value for #{key}: #{value.inspect}. " \
            "Expected one of: true, false, 1, 0, yes, no"
    end

    # Build a service URL: {scheme}://{subdomain}.{base_domain}
    def service_url(scheme, subdomain, base_domain)
      "#{scheme}://#{subdomain}.#{base_domain}"
    end

    # Minimal INI parser. Returns { section_name => { key => value, ... } }.
    def parse_ini(text)
      sections = {}
      current = nil
      text.each_line do |line|
        line = line.strip
        next if line.empty? || line.start_with?("#", ";")

        if line.start_with?("[") && line.end_with?("]")
          name = line[1..-2].strip
          current = (sections[name] ||= {})
        elsif current
          key, _, value = line.partition("=")
          next if value.empty? && !line.include?("=")

          current[key.strip] = value.strip
        end
      end
      sections
    end

    def read_config_file(profile, home_dir: nil)
      home_dir ||= Dir.home
      path = File.join(home_dir, ".smplkit")
      return {} unless File.file?(path)

      sections =
        begin
          # Force UTF-8 — the file may contain comments with non-ASCII bytes
          # (em dashes, smart quotes) and the system's default external
          # encoding is locale-dependent.
          parse_ini(File.read(path, encoding: "UTF-8"))
        rescue StandardError
          return {}
        end

      values = {}
      sections.fetch("common", {}).each { |k, v| values[k] = v unless v.empty? }

      if sections.key?(profile)
        sections[profile].each { |k, v| values[k] = v unless v.empty? }
      else
        non_common = sections.keys.reject { |s| s == "common" }
        if !non_common.empty? && profile != "default"
          raise Error,
                "Profile [#{profile}] not found in ~/.smplkit. Available profiles: #{non_common.join(", ")}"
        end
      end

      values
    end

    def resolve_config(profile: nil, api_key: nil, base_domain: nil, scheme: nil,
                       environment: nil, service: nil, debug: nil, telemetry: nil,
                       home_dir: nil)
      resolved = DEFAULTS.dup

      active_profile = profile || ENV["SMPLKIT_PROFILE"] || "default"

      file_values = read_config_file(active_profile, home_dir: home_dir)
      CONFIG_KEYS.each_key do |key|
        next unless file_values.key?(key)

        val = file_values[key]
        resolved[key] = %w[debug telemetry].include?(key) ? parse_bool(val, key) : val
      end

      CONFIG_KEYS.each do |key, env_var|
        env_val = ENV.fetch(env_var, "")
        next if env_val.empty?

        resolved[key] = %w[debug telemetry].include?(key) ? parse_bool(env_val, env_var) : env_val
      end

      ctor = {
        "api_key" => api_key, "base_domain" => base_domain, "scheme" => scheme,
        "environment" => environment, "service" => service,
        "debug" => debug, "telemetry" => telemetry
      }
      ctor.each { |k, v| resolved[k] = v unless v.nil? }

      missing_required(resolved, "environment", active_profile)
      missing_required(resolved, "service", active_profile)
      missing_required(resolved, "api_key", active_profile)

      ResolvedConfig.new(
        api_key: resolved["api_key"].to_s,
        base_domain: resolved["base_domain"].to_s,
        scheme: resolved["scheme"].to_s,
        environment: resolved["environment"].to_s,
        service: resolved["service"].to_s,
        debug: resolved["debug"] ? true : false,
        telemetry: resolved["telemetry"] ? true : false
      )
    end

    def resolve_management_config(profile: nil, api_key: nil, base_domain: nil,
                                  scheme: nil, debug: nil, home_dir: nil)
      resolved = {
        "api_key" => nil,
        "base_domain" => "smplkit.com",
        "scheme" => "https",
        "debug" => false
      }

      active_profile = profile || ENV["SMPLKIT_PROFILE"] || "default"

      file_values = read_config_file(active_profile, home_dir: home_dir)
      %w[api_key base_domain scheme debug].each do |key|
        next unless file_values.key?(key)

        val = file_values[key]
        resolved[key] = key == "debug" ? parse_bool(val, key) : val
      end

      [
        %w[api_key SMPLKIT_API_KEY], %w[base_domain SMPLKIT_BASE_DOMAIN],
        %w[scheme SMPLKIT_SCHEME], %w[debug SMPLKIT_DEBUG]
      ].each do |key, env_var|
        env_val = ENV.fetch(env_var, "")
        next if env_val.empty?

        resolved[key] = key == "debug" ? parse_bool(env_val, env_var) : env_val
      end

      ctor = { "api_key" => api_key, "base_domain" => base_domain, "scheme" => scheme, "debug" => debug }
      ctor.each { |k, v| resolved[k] = v unless v.nil? }

      missing_required(resolved, "api_key", active_profile)

      ResolvedManagementConfig.new(
        api_key: resolved["api_key"].to_s,
        base_domain: resolved["base_domain"].to_s,
        scheme: resolved["scheme"].to_s,
        debug: resolved["debug"] ? true : false
      )
    end

    def missing_required(resolved, key, profile)
      return if resolved[key]

      env_var = CONFIG_KEYS[key]
      raise Error,
            "No #{key} provided. Set one of:\n  " \
            "1. Pass #{key} to the constructor\n  " \
            "2. Set the #{env_var} environment variable\n  " \
            "3. Add #{key} to the [#{profile}] section in ~/.smplkit"
    end
  end
end
