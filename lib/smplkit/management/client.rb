# frozen_string_literal: true

require "faraday"
require "json"
require "concurrent"

module Smplkit
  # Top-level management client. Owns the HTTP transports + CRUD APIs for
  # every resource on the smplkit platform.
  #
  # Sub-namespaces (mirroring the Python SDK):
  #
  #   - +mgmt.contexts.*+
  #   - +mgmt.context_types.*+
  #   - +mgmt.environments.*+
  #   - +mgmt.account_settings.*+
  #   - +mgmt.config.*+
  #   - +mgmt.flags.*+
  #   - +mgmt.loggers.*+
  #   - +mgmt.log_groups.*+
  #
  # Constructable both as +Smplkit::ManagementClient.new+ (standalone) and as
  # +Smplkit::Client#manage+ (shared transports).
  class ManagementClient
    attr_reader :contexts, :context_types, :environments, :account_settings,
                :config, :flags, :loggers, :log_groups

    def self.from_resolved(resolved)
      new(_resolved: resolved)
    end

    def initialize(api_key: nil, base_domain: nil, scheme: nil, profile: nil,
                   debug: nil, _resolved: nil)
      cfg = _resolved ||
            ConfigResolution.resolve_management_config(
              api_key: api_key, base_domain: base_domain, scheme: scheme,
              profile: profile, debug: debug
            )
      Smplkit.enable_debug if cfg.debug

      @resolved = cfg
      @app_http = build_http(ConfigResolution.service_url(cfg.scheme, "app", cfg.base_domain), cfg.api_key)
      @config_http = build_http(ConfigResolution.service_url(cfg.scheme, "config", cfg.base_domain), cfg.api_key)
      @flags_http = build_http(ConfigResolution.service_url(cfg.scheme, "flags", cfg.base_domain), cfg.api_key)
      @logging_http = build_http(ConfigResolution.service_url(cfg.scheme, "logging", cfg.base_domain), cfg.api_key)

      @contexts = ContextsNamespace.new(@app_http)
      @context_types = ContextTypesNamespace.new(@app_http)
      @environments = EnvironmentsNamespace.new(@app_http)
      @account_settings = AccountSettingsNamespace.new(@app_http)
      @config = ConfigNamespace.new(@config_http)
      @flags = FlagsNamespace.new(@flags_http)
      @loggers = LoggersNamespace.new(@logging_http)
      @log_groups = LogGroupsNamespace.new(@logging_http)
    end

    def close
      [@app_http, @config_http, @flags_http, @logging_http].each do |conn|
        conn.close if conn.respond_to?(:close)
      end
    end

    def _resolved = @resolved
    def _app_http = @app_http
    def _config_http = @config_http
    def _flags_http = @flags_http
    def _logging_http = @logging_http

    private

    def build_http(base_url, api_key)
      Faraday.new(url: base_url) do |f|
        f.request :authorization, "Bearer", api_key
        f.headers["Content-Type"] = "application/vnd.api+json"
        f.headers["Accept"] = "application/vnd.api+json"
        f.headers["User-Agent"] = "smplkit-ruby-sdk/#{Smplkit::VERSION}"
        f.adapter Faraday.default_adapter
      end
    end

    # ------------------------------------------------------------------
    # Sub-namespaces
    # ------------------------------------------------------------------

    # Shared HTTP helpers used by every namespace below.
    #
    # All methods are prefixed +http_+ to avoid colliding with the public
    # +get+ / +list+ accessors on each namespace.
    module HttpHelpers
      private

      def http_get(path)
        response = @http.get(path)
        Errors.raise_for_status(response.status, response.body)
        response.body.to_s.empty? ? {} : JSON.parse(response.body)
      end

      def http_list(path)
        body = http_get(path)
        body["data"] || []
      end

      def http_post(path, body)
        response = @http.post(path) do |req|
          req.body = body.is_a?(String) ? body : JSON.generate(body)
        end
        Errors.raise_for_status(response.status, response.body)
        response.body.to_s.empty? ? {} : JSON.parse(response.body)
      end

      def http_put(path, body)
        response = @http.put(path) do |req|
          req.body = body.is_a?(String) ? body : JSON.generate(body)
        end
        Errors.raise_for_status(response.status, response.body)
        response.body.to_s.empty? ? {} : JSON.parse(response.body)
      end

      def http_delete(path)
        response = @http.delete(path)
        Errors.raise_for_status(response.status, response.body)
        true
      end
    end

    class ContextsNamespace
      include HttpHelpers

      def initialize(http)
        @http = http
        @buffer = Management::ContextRegistrationBuffer.new
      end

      def register(contexts)
        return if contexts.nil? || contexts.empty?

        @buffer.observe(contexts)
        flush if @buffer.pending_count >= Management::CONTEXT_BATCH_FLUSH_SIZE
      end

      def flush
        batch = @buffer.drain
        return if batch.empty?

        body = { "data" => { "type" => "context_bulk_register", "attributes" => { "contexts" => batch } } }
        http_post("/api/contexts/v1/bulk", body)
      rescue StandardError => e
        Smplkit.debug("registration", "context flush failed: #{e.class}: #{e.message}")
      end

      def list
        list_resp = http_list("/api/contexts/v1")
        list_resp.map { |r| context_from_resource(r) }
      end

      def get(id_or_type, key = nil)
        type, ckey = split_id(id_or_type, key)
        resource = http_get("/api/contexts/v1/#{type}:#{ckey}")
        context_from_resource(resource["data"])
      end

      def delete(id_or_type, key = nil)
        type, ckey = split_id(id_or_type, key)
        http_delete("/api/contexts/v1/#{type}:#{ckey}")
      end

      def _save_context(ctx)
        body = {
          "data" => {
            "type" => "context",
            "id" => ctx.id,
            "attributes" => { "type" => ctx.type, "key" => ctx.key, "attributes" => ctx.attributes }.compact
          }
        }
        resp = http_put("/api/contexts/v1/#{ctx.id}", body)
        context_from_resource(resp["data"]).tap { |c| c._bind_client(self) }
      end

      private

      def split_id(id_or_type, key)
        return [id_or_type, key] if key

        unless id_or_type.include?(":")
          raise ArgumentError, "context id must be 'type:key' (got #{id_or_type.inspect}); " \
                               "alternatively pass type and key as separate args"
        end

        id_or_type.split(":", 2)
      end

      def context_from_resource(resource)
        attrs = resource["attributes"] || {}
        Smplkit::Context.new(
          attrs["type"] || resource["id"].to_s.split(":").first,
          attrs["key"] || resource["id"].to_s.split(":", 2).last,
          attrs["attributes"] || {},
          name: attrs["name"],
          created_at: attrs["created_at"],
          updated_at: attrs["updated_at"]
        )._bind_client(self)
      end
    end

    class ContextTypesNamespace
      include HttpHelpers

      def initialize(http)
        @http = http
      end

      def list
        list_resp = http_list("/api/context_types/v1")
        list_resp.map { |r| from_resource(r) }
      end

      def get(key)
        resp = http_get("/api/context_types/v1/#{key}")
        from_resource(resp["data"])
      end

      def delete(key)
        http_delete("/api/context_types/v1/#{key}")
      end

      def new_context_type(key, name: nil, description: nil)
        Management::ContextType.new(self, key: key, name: name, description: description)
      end

      def _create_context_type(ct)
        resp = http_post("/api/context_types/v1", body_for(ct))
        from_resource(resp["data"])
      end

      def _update_context_type(ct)
        resp = http_put("/api/context_types/v1/#{ct.key}", body_for(ct))
        from_resource(resp["data"])
      end

      private

      def body_for(ct)
        {
          "data" => {
            "type" => "context_type",
            "id" => ct.key,
            "attributes" => { "key" => ct.key, "name" => ct.name, "description" => ct.description }.compact
          }
        }
      end

      def from_resource(resource)
        attrs = resource["attributes"] || {}
        Management::ContextType.new(
          self,
          id: resource["id"], key: attrs["key"] || resource["id"],
          name: attrs["name"], description: attrs["description"],
          created_at: attrs["created_at"], updated_at: attrs["updated_at"]
        )
      end
    end

    class EnvironmentsNamespace
      include HttpHelpers

      def initialize(http)
        @http = http
      end

      def list
        list_resp = http_list("/api/environments/v1")
        list_resp.map { |r| from_resource(r) }
      end

      def get(key)
        resp = http_get("/api/environments/v1/#{key}")
        from_resource(resp["data"])
      end

      def delete(key)
        http_delete("/api/environments/v1/#{key}")
      end

      def new(key, name: nil, color: nil,
              classification: Management::EnvironmentClassification::STANDARD,
              description: nil)
        color = Management::Color.new(color) if color.is_a?(String)
        Management::Environment.new(
          self,
          key: key, name: name || Smplkit::Helpers.key_to_display_name(key),
          color: color, classification: classification, description: description
        )
      end

      def _create_environment(env)
        resp = http_post("/api/environments/v1", body_for(env))
        from_resource(resp["data"])
      end

      def _update_environment(env)
        resp = http_put("/api/environments/v1/#{env.key}", body_for(env))
        from_resource(resp["data"])
      end

      private

      def body_for(env)
        {
          "data" => {
            "type" => "environment",
            "id" => env.key,
            "attributes" => {
              "key" => env.key,
              "name" => env.name,
              "color" => env.color&.hex,
              "classification" => env.classification,
              "description" => env.description
            }.compact
          }
        }
      end

      def from_resource(resource)
        attrs = resource["attributes"] || {}
        color = attrs["color"] && Management::Color.new(attrs["color"])
        Management::Environment.new(
          self,
          id: resource["id"], key: attrs["key"] || resource["id"],
          name: attrs["name"], color: color,
          classification: attrs["classification"] || Management::EnvironmentClassification::STANDARD,
          description: attrs["description"],
          created_at: attrs["created_at"], updated_at: attrs["updated_at"]
        )
      end
    end

    class AccountSettingsNamespace
      include HttpHelpers

      def initialize(http)
        @http = http
      end

      def get
        resp = http_get("/api/account_settings/v1")
        from_resource(resp["data"])
      end

      def _update_account_settings(settings)
        resp = http_put("/api/account_settings/v1", body_for(settings))
        from_resource(resp["data"])
      end

      private

      def body_for(settings)
        {
          "data" => {
            "type" => "account_settings",
            "attributes" => {
              "environment_order" => settings.environment_order,
              "default_environment" => settings.default_environment
            }.compact
          }
        }
      end

      def from_resource(resource)
        attrs = resource["attributes"] || {}
        Management::AccountSettings.new(
          self,
          id: resource["id"],
          environment_order: attrs["environment_order"] || [],
          default_environment: attrs["default_environment"],
          updated_at: attrs["updated_at"]
        )
      end
    end

    class ConfigNamespace
      include HttpHelpers

      def initialize(http)
        @http = http
      end

      def list
        list_resp = http_list("/api/configs/v1")
        list_resp.map { |r| Smplkit::Config::Helpers.config_from_json(self, r) }
      end

      def get(key)
        resp = http_get("/api/configs/v1/#{key}")
        Smplkit::Config::Helpers.config_from_json(self, resp["data"])
      end

      def delete(key)
        http_delete("/api/configs/v1/#{key}")
      end

      def new_config(key, name: nil, description: nil, parent: nil)
        Smplkit::Config::Config.new(
          self, key: key, name: name, description: description,
                parent_id: parent.is_a?(Smplkit::Config::Config) ? parent.key : parent
        )
      end

      def _create_config(config)
        body = Smplkit::Config::Helpers.build_config_request_body(config)
        resp = http_post("/api/configs/v1", body)
        Smplkit::Config::Helpers.config_from_json(self, resp["data"])
      end

      def _update_config(config)
        body = Smplkit::Config::Helpers.build_config_request_body(config)
        resp = http_put("/api/configs/v1/#{config.key}", body)
        Smplkit::Config::Helpers.config_from_json(self, resp["data"])
      end

      def fetch_chain(key)
        resp = http_get("/api/configs/v1/#{key}/chain")
        (resp["data"] || []).map { |r| r["attributes"] || {} }
      end
    end

    class FlagsNamespace
      include HttpHelpers

      def initialize(http)
        @http = http
        @buffer = Management::FlagRegistrationBuffer.new
      end

      def register(declaration)
        @buffer.add(declaration)
        flush if @buffer.pending_count >= Management::FLAG_BATCH_FLUSH_SIZE
      end

      def flush
        batch = @buffer.drain
        return if batch.empty?

        body = { "data" => { "type" => "flag_bulk_register", "attributes" => { "flags" => batch } } }
        http_post("/api/flags/v1/bulk", body)
      rescue StandardError => e
        Smplkit.debug("registration", "flag flush failed: #{e.class}: #{e.message}")
      end

      def list
        list_resp = http_list("/api/flags/v1")
        list_resp.map { |r| flag_from_resource(r) }
      end

      def get(id)
        resp = http_get("/api/flags/v1/#{id}")
        flag_from_resource(resp["data"])
      end

      def delete(id)
        http_delete("/api/flags/v1/#{id}")
      end

      def new_boolean_flag(id, default:, name: nil, description: nil, values: nil)
        Smplkit::Flags::BooleanFlag.new(
          self, id: id, name: name || id, type: "BOOLEAN", default: default,
                description: description, values: values
        )
      end

      def new_string_flag(id, default:, name: nil, description: nil, values: nil)
        Smplkit::Flags::StringFlag.new(
          self, id: id, name: name || id, type: "STRING", default: default,
                description: description, values: values
        )
      end

      def new_number_flag(id, default:, name: nil, description: nil, values: nil)
        Smplkit::Flags::NumberFlag.new(
          self, id: id, name: name || id, type: "NUMERIC", default: default,
                description: description, values: values
        )
      end

      def new_json_flag(id, default:, name: nil, description: nil, values: nil)
        Smplkit::Flags::JsonFlag.new(
          self, id: id, name: name || id, type: "JSON", default: default,
                description: description, values: values
        )
      end

      def _create_flag(flag)
        body = Smplkit::Flags::Helpers.build_flag_request_body(flag)
        resp = http_post("/api/flags/v1", body)
        flag_from_resource(resp["data"])
      end

      def _update_flag(flag)
        body = Smplkit::Flags::Helpers.build_flag_request_body(flag)
        resp = http_put("/api/flags/v1/#{flag.id}", body)
        flag_from_resource(resp["data"])
      end

      def fetch_flag(id)
        resp = http_get("/api/flags/v1/#{id}")
        Smplkit::Flags::Helpers.flag_dict_from_json(resp["data"])
      end

      def list_flags
        body = http_list("/api/flags/v1")
        body.map { |r| Smplkit::Flags::Helpers.flag_dict_from_json(r) }
      end

      private

      def flag_from_resource(resource)
        d = Smplkit::Flags::Helpers.flag_dict_from_json(resource)
        klass =
          case d["type"]
          when "BOOLEAN" then Smplkit::Flags::BooleanFlag
          when "STRING" then Smplkit::Flags::StringFlag
          when "NUMERIC" then Smplkit::Flags::NumberFlag
          else Smplkit::Flags::JsonFlag
          end
        klass.new(
          self,
          id: d["id"], name: d["name"], type: d["type"], default: d["default"],
          description: d["description"], values: d["values"], environments: d["environments"],
          created_at: (resource["attributes"] || {})["created_at"],
          updated_at: (resource["attributes"] || {})["updated_at"]
        )
      end
    end

    class LoggersNamespace
      include HttpHelpers

      def initialize(http)
        @http = http
        @buffer = Management::LoggerRegistrationBuffer.new
      end

      def register(source)
        sources = source.is_a?(Array) ? source : [source]
        sources.each { |s| @buffer.add(s) }
        flush if @buffer.pending_count >= Management::LOGGER_BATCH_FLUSH_SIZE
      end

      def flush
        batch = @buffer.drain
        return if batch.empty?

        body = { "data" => { "type" => "logger_bulk_register", "attributes" => { "loggers" => batch } } }
        http_post("/api/loggers/v1/bulk", body)
      rescue StandardError => e
        Smplkit.debug("registration", "logger flush failed: #{e.class}: #{e.message}")
      end

      def list
        list_resp = http_list("/api/loggers/v1")
        list_resp.map { |r| Smplkit::Logging::Helpers.logger_resource_to_model(self, r) }
      end

      def get(id)
        normalized = Smplkit::Logging::Normalize.normalize_logger_name(id)
        resp = http_get("/api/loggers/v1/#{normalized}")
        Smplkit::Logging::Helpers.logger_resource_to_model(self, resp["data"])
      end

      def delete(id)
        normalized = Smplkit::Logging::Normalize.normalize_logger_name(id)
        http_delete("/api/loggers/v1/#{normalized}")
      end

      def _update_logger(logger)
        body = Smplkit::Logging::Helpers.build_logger_body(logger)
        resp = http_put("/api/loggers/v1/#{logger.id || logger.name}", body)
        Smplkit::Logging::Helpers.logger_resource_to_model(self, resp["data"])
      end
    end

    class LogGroupsNamespace
      include HttpHelpers

      def initialize(http)
        @http = http
      end

      def list
        list_resp = http_list("/api/log_groups/v1")
        list_resp.map { |r| Smplkit::Logging::Helpers.log_group_resource_to_model(self, r) }
      end

      def get(key)
        resp = http_get("/api/log_groups/v1/#{key}")
        Smplkit::Logging::Helpers.log_group_resource_to_model(self, resp["data"])
      end

      def delete(key)
        http_delete("/api/log_groups/v1/#{key}")
      end

      def new_log_group(key, name: nil, level: nil, description: nil, parent: nil)
        Smplkit::Logging::SmplLogGroup.new(
          self, key: key, name: name || Smplkit::Helpers.key_to_display_name(key),
                level: level && Smplkit::LogLevel.coerce(level), description: description,
                parent_id: parent.is_a?(Smplkit::Logging::SmplLogGroup) ? parent.key : parent
        )
      end

      def _create_log_group(group)
        body = Smplkit::Logging::Helpers.build_log_group_body(group)
        resp = http_post("/api/log_groups/v1", body)
        Smplkit::Logging::Helpers.log_group_resource_to_model(self, resp["data"])
      end

      def _update_log_group(group)
        body = Smplkit::Logging::Helpers.build_log_group_body(group)
        resp = http_put("/api/log_groups/v1/#{group.key}", body)
        Smplkit::Logging::Helpers.log_group_resource_to_model(self, resp["data"])
      end
    end
  end
end
