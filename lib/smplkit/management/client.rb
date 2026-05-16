# frozen_string_literal: true

require "json"

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
  #
  # Each namespace is wired to a generated +SmplkitGeneratedClient+ +ApiClient+
  # under the hood — auth, request encoding, and response parsing flow through
  # the openapi-generator-produced layer in +lib/smplkit/_generated+. The
  # wrapper layer keeps the customer-facing domain models (+Flag+, +Config+,
  # etc.) and converts at the boundary via the existing
  # +<resource>_from_resource+ helpers.
  class ManagementClient
    # Default page[size] the runtime asks for when walking a list
    # endpoint to completion. The platform caps page[size] at 1000;
    # using the same value here makes the minimum number of round-trips
    # per exhaustive fetch.
    RUNTIME_PAGE_SIZE = 1000

    attr_reader :contexts, :context_types, :environments, :account_settings,
                :config, :flags, :loggers, :log_groups, :audit

    def self.from_resolved(resolved, extra_headers: nil)
      new(_resolved: resolved, extra_headers: extra_headers)
    end

    def initialize(api_key: nil, base_domain: nil, scheme: nil, profile: nil,
                   debug: nil, _resolved: nil, extra_headers: nil)
      cfg = _resolved ||
            ConfigResolution.resolve_management_config(
              api_key: api_key, base_domain: base_domain, scheme: scheme,
              profile: profile, debug: debug
            )
      Smplkit.enable_debug if cfg.debug

      @resolved = cfg

      @extra_headers = extra_headers
      @app_api_client = build_api_client(SmplkitGeneratedClient::App, "app", cfg)
      @config_api_client = build_api_client(SmplkitGeneratedClient::Config, "config", cfg)
      @flags_api_client = build_api_client(SmplkitGeneratedClient::Flags, "flags", cfg)
      @logging_api_client = build_api_client(SmplkitGeneratedClient::Logging, "logging", cfg)
      @audit_api_client = build_api_client(SmplkitGeneratedClient::Audit, "audit", cfg)

      @contexts = ContextsNamespace.new(@app_api_client)
      @context_types = ContextTypesNamespace.new(@app_api_client)
      @environments = EnvironmentsNamespace.new(@app_api_client)
      @account_settings = AccountSettingsNamespace.new(@app_api_client)
      @config = ConfigNamespace.new(@config_api_client)
      @flags = FlagsNamespace.new(@flags_api_client)
      @loggers = LoggersNamespace.new(@logging_api_client)
      @log_groups = LogGroupsNamespace.new(@logging_api_client)
      @audit = Management::AuditNamespace.new(@audit_api_client)
    end

    def close
      # The generated ApiClient owns Faraday connections that release on GC.
      # No explicit shutdown is exposed; this stub keeps the API stable.
    end

    def _resolved = @resolved
    def _app_http = @app_api_client
    def _config_http = @config_api_client
    def _flags_http = @flags_api_client
    def _logging_http = @logging_api_client
    def _audit_http = @audit_api_client

    SDK_OWNED_HEADERS = %w[authorization content-type user-agent].freeze

    private

    def build_api_client(generated_module, subdomain, cfg)
      configuration = generated_module::Configuration.new
      configuration.scheme = cfg.scheme
      configuration.host = "#{subdomain}.#{cfg.base_domain}"
      configuration.base_path = ""
      configuration.access_token = cfg.api_key
      configuration.debugging = cfg.debug
      generated_module::ApiClient.new(configuration).tap do |client|
        client.default_headers["User-Agent"] = "smplkit-ruby-sdk/#{Smplkit::VERSION}"
        @extra_headers&.each do |k, v|
          client.default_headers[k] = v unless SDK_OWNED_HEADERS.include?(k.downcase)
        end
      end
    end

    # ------------------------------------------------------------------
    # Shared error-mapping wrapper
    # ------------------------------------------------------------------

    # Wraps a generated-API call and converts any +ApiError+ raised by the
    # generated layer into the +Smplkit::Error+ hierarchy. Connection-level
    # failures (no response from the server) become +Smplkit::ConnectionError+;
    # status-coded failures route through +Errors.raise_for_status+ which
    # emits +NotFoundError+ / +ConflictError+ / +ValidationError+ / +Error+
    # depending on the JSON:API body.
    module ErrorMapping
      module_function

      def call
        yield
      rescue StandardError => e
        raise unless generated_api_error?(e)

        raise Smplkit::ConnectionError, e.message.to_s if e.code.nil? || e.code.zero?

        Smplkit::Errors.raise_for_status(e.code, e.response_body.to_s)
        # raise_for_status only returns on 2xx; if we get here the generated
        # layer raised on a 2xx (shouldn't happen) so re-raise the original.
        raise
      end

      def generated_api_error?(err)
        klass_name = err.class.name.to_s
        klass_name.start_with?("SmplkitGeneratedClient::") && klass_name.end_with?("::ApiError")
      end
    end

    # Walk a generated paginated list endpoint to completion.
    #
    # The block receives a per-page +opts+ hash with +page_number+ and
    # +page_size+ filled in, calls the generated list method through
    # {ErrorMapping.call}, and returns the response object. Pages stop
    # when the server returns fewer rows than requested — the platform's
    # standard last-page signal across every offset-paginated list
    # endpoint. Returns the concatenated +response.data+ rows.
    module PaginatedFetch
      module_function

      def collect(page_size: RUNTIME_PAGE_SIZE)
        rows = []
        page_number = 1
        loop do
          opts = { page_number: page_number, page_size: page_size }
          response = ErrorMapping.call { yield(opts) }
          page = response.data || []
          rows.concat(page)
          break if page.length < page_size

          page_number += 1
        end
        rows
      end
    end

    # Deep-stringify Hash keys so resources returned by generated +to_hash+
    # (symbol-keyed) match what the wrapper helpers expect (string-keyed).
    module ResourceShim
      module_function

      def stringify(value)
        Smplkit::Helpers.deep_stringify_keys(value)
      end

      # Convenience: produce a string-keyed Hash from a generated model.
      def from_model(model)
        return {} if model.nil?

        stringify(model.to_hash)
      end
    end

    # ------------------------------------------------------------------
    # Sub-namespaces
    # ------------------------------------------------------------------

    class ContextsNamespace
      def initialize(api_client)
        @api = SmplkitGeneratedClient::App::ContextsApi.new(api_client)
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

        items = batch.map do |entry|
          SmplkitGeneratedClient::App::ContextBulkItem.new(
            type: entry["type"], key: entry["key"], attributes: entry["attributes"] || {}
          )
        end
        body = SmplkitGeneratedClient::App::ContextBulkRegister.new(contexts: items)
        ErrorMapping.call { @api.bulk_register_contexts(body) }
      rescue StandardError => e
        Smplkit.debug("registration", "context flush failed: #{e.class}: #{e.message}")
      end

      def list(page_number: nil, page_size: nil)
        opts = {}
        opts[:page_number] = page_number unless page_number.nil?
        opts[:page_size] = page_size unless page_size.nil?
        response = ErrorMapping.call { @api.list_contexts(opts) }
        (response.data || []).map { |r| context_from_resource(ResourceShim.from_model(r)) }
      end

      def get(id_or_type, key = nil)
        type, ckey = split_id(id_or_type, key)
        response = ErrorMapping.call { @api.get_context("#{type}:#{ckey}") }
        context_from_resource(ResourceShim.from_model(response.data))
      end

      def delete(id_or_type, key = nil)
        type, ckey = split_id(id_or_type, key)
        ErrorMapping.call { @api.delete_context("#{type}:#{ckey}") }
        true
      end

      def _save_context(ctx)
        body = SmplkitGeneratedClient::App::ContextResponse.new(
          data: SmplkitGeneratedClient::App::ContextResource.new(
            type: "context",
            id: ctx.id,
            attributes: SmplkitGeneratedClient::App::Context.new(
              name: ctx.name, context_type: ctx.type, attributes: ctx.attributes
            )
          )
        )
        response = ErrorMapping.call { @api.update_context(ctx.id, body) }
        context_from_resource(ResourceShim.from_model(response.data)).tap { |c| c._bind_client(self) }
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
          attrs["context_type"] || attrs["type"] || resource["id"].to_s.split(":").first,
          attrs["key"] || resource["id"].to_s.split(":", 2).last,
          attrs["attributes"] || {},
          name: attrs["name"],
          created_at: attrs["created_at"],
          updated_at: attrs["updated_at"]
        )._bind_client(self)
      end
    end

    class ContextTypesNamespace
      def initialize(api_client)
        @api = SmplkitGeneratedClient::App::ContextTypesApi.new(api_client)
      end

      def list(page_number: nil, page_size: nil)
        opts = {}
        opts[:page_number] = page_number unless page_number.nil?
        opts[:page_size] = page_size unless page_size.nil?
        response = ErrorMapping.call { @api.list_context_types(opts) }
        (response.data || []).map { |r| from_resource(ResourceShim.from_model(r)) }
      end

      def get(key)
        response = ErrorMapping.call { @api.get_context_type(key) }
        from_resource(ResourceShim.from_model(response.data))
      end

      def delete(key)
        ErrorMapping.call { @api.delete_context_type(key) }
        true
      end

      def new_context_type(key, name: nil, description: nil)
        Management::ContextType.new(self, key: key, name: name, description: description)
      end

      def _create_context_type(ct)
        response = ErrorMapping.call { @api.create_context_type(body_for(ct)) }
        from_resource(ResourceShim.from_model(response.data))
      end

      def _update_context_type(ct)
        response = ErrorMapping.call { @api.update_context_type(ct.key, body_for(ct)) }
        from_resource(ResourceShim.from_model(response.data))
      end

      private

      def body_for(ct)
        # ContextType server schema: name, attributes, created_at, updated_at.
        # Customer-side +description+ is wrapper-only; not sent on the wire.
        SmplkitGeneratedClient::App::ContextTypeResponse.new(
          data: SmplkitGeneratedClient::App::ContextTypeResource.new(
            type: "context_type",
            id: ct.key,
            attributes: SmplkitGeneratedClient::App::ContextType.new(name: ct.name)
          )
        )
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
      def initialize(api_client)
        @api = SmplkitGeneratedClient::App::EnvironmentsApi.new(api_client)
      end

      def list(page_number: nil, page_size: nil)
        opts = {}
        opts[:page_number] = page_number unless page_number.nil?
        opts[:page_size] = page_size unless page_size.nil?
        response = ErrorMapping.call { @api.list_environments(opts) }
        (response.data || []).map { |r| from_resource(ResourceShim.from_model(r)) }
      end

      def get(key)
        response = ErrorMapping.call { @api.get_environment(key) }
        from_resource(ResourceShim.from_model(response.data))
      end

      def delete(key)
        ErrorMapping.call { @api.delete_environment(key) }
        true
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
        response = ErrorMapping.call { @api.create_environment(body_for(env)) }
        from_resource(ResourceShim.from_model(response.data))
      end

      def _update_environment(env)
        response = ErrorMapping.call { @api.update_environment(env.key, body_for(env)) }
        from_resource(ResourceShim.from_model(response.data))
      end

      private

      def body_for(env)
        # Environment server schema: name, color, classification.
        # Customer-side +description+ stays wrapper-only.
        SmplkitGeneratedClient::App::EnvironmentResponse.new(
          data: SmplkitGeneratedClient::App::EnvironmentResource.new(
            type: "environment",
            id: env.key,
            attributes: SmplkitGeneratedClient::App::Environment.new(
              name: env.name,
              color: env.color&.hex,
              classification: env.classification
            )
          )
        )
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
      def initialize(api_client)
        @api = SmplkitGeneratedClient::App::AccountApi.new(api_client)
      end

      def get
        raw = ErrorMapping.call { @api.get_account_settings }
        from_raw(raw)
      end

      def _update_account_settings(settings)
        # The generator pulled this op without wiring a body parameter
        # (the server accepts a free-form JSON object). The +debug_body+
        # opt is the documented escape hatch.
        raw = ErrorMapping.call do
          @api.put_account_settings(debug_body: settings_body(settings))
        end
        from_raw(raw)
      end

      private

      def settings_body(settings)
        {
          "environment_order" => settings.environment_order,
          "default_environment" => settings.default_environment
        }.compact
      end

      def from_raw(raw)
        attrs = raw.respond_to?(:to_hash) ? ResourceShim.stringify(raw.to_hash) : (raw || {})
        if attrs.is_a?(Hash) && attrs["data"].is_a?(Hash) && attrs["data"]["attributes"]
          attrs = attrs["data"]["attributes"]
        end
        Management::AccountSettings.new(
          self,
          id: attrs["id"],
          environment_order: attrs["environment_order"] || [],
          default_environment: attrs["default_environment"],
          updated_at: attrs["updated_at"]
        )
      end
    end

    class ConfigNamespace
      def initialize(api_client)
        @api = SmplkitGeneratedClient::Config::ConfigsApi.new(api_client)
      end

      def list(page_number: nil, page_size: nil)
        opts = {}
        opts[:page_number] = page_number unless page_number.nil?
        opts[:page_size] = page_size unless page_size.nil?
        response = ErrorMapping.call { @api.list_configs(opts) }
        (response.data || []).map { |r| Smplkit::Config::Helpers.config_from_json(self, ResourceShim.from_model(r)) }
      end

      def get(key)
        response = ErrorMapping.call { @api.get_config(key) }
        Smplkit::Config::Helpers.config_from_json(self, ResourceShim.from_model(response.data))
      end

      def delete(key)
        ErrorMapping.call { @api.delete_config(key) }
        true
      end

      def new_config(key, name: nil, description: nil, parent: nil)
        Smplkit::Config::Config.new(
          self,
          key: key,
          name: name || Smplkit::Helpers.key_to_display_name(key),
          description: description,
          parent_id: parent.is_a?(Smplkit::Config::Config) ? parent.key : parent
        )
      end

      def _create_config(config)
        response = ErrorMapping.call { @api.create_config(config_body(config)) }
        Smplkit::Config::Helpers.config_from_json(self, ResourceShim.from_model(response.data))
      end

      def _update_config(config)
        response = ErrorMapping.call { @api.update_config(config.key, config_body(config)) }
        Smplkit::Config::Helpers.config_from_json(self, ResourceShim.from_model(response.data))
      end

      # Build the parent-chain for a given config, walking +parent_id+
      # pointers across the full config list. Mirrors the Python SDK's
      # client-side resolution — there is no server +/chain+ endpoint.
      #
      # Walks every page of +list_configs+ so an account with more than
      # +RUNTIME_PAGE_SIZE+ configs still resolves chains correctly.
      def fetch_chain(target_key)
        all_configs = fetch_all_configs
        by_key = all_configs.to_h { |c| [c.key, c] }
        by_id = all_configs.to_h { |c| [c.id, c] }

        current = by_key[target_key]
        return [] unless current

        chain = []
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

      private

      def fetch_all_configs
        rows = PaginatedFetch.collect { |opts| @api.list_configs(opts) }
        rows.map { |r| Smplkit::Config::Helpers.config_from_json(self, ResourceShim.from_model(r)) }
      end

      def config_body(config)
        SmplkitGeneratedClient::Config::ConfigResponse.new(
          data: SmplkitGeneratedClient::Config::ConfigResource.new(
            type: "config",
            id: config.key,
            attributes: SmplkitGeneratedClient::Config::Config.new(
              name: config.name,
              description: config.description,
              parent: config.parent_id,
              items: config_items_to_wire(config.items),
              environments: config_envs_to_wire(config.environments)
            )
          )
        )
      end

      def config_items_to_wire(items)
        return nil if items.nil? || items.empty?

        items.to_h do |item|
          [item.name, SmplkitGeneratedClient::Config::ConfigItemDefinition.new(
            value: item.value, type: item.type, description: item.description
          )]
        end
      end

      def config_envs_to_wire(environments)
        return nil if environments.empty?

        # ConfigItemOverride only carries +value+ on the wire — environment
        # overrides override the value, not the type or description.
        environments.each_with_object({}) do |(env_key, env_obj), out|
          values = env_obj.values_raw.each_with_object({}) do |(k, v), inner|
            v_hash = v.is_a?(Hash) ? v : { "value" => v }
            inner[k] = SmplkitGeneratedClient::Config::ConfigItemOverride.new(value: v_hash["value"])
          end
          out[env_key] = SmplkitGeneratedClient::Config::EnvironmentOverride.new(values: values)
        end
      end

      def config_to_chain_entry(config)
        items_hash = {}
        config.items.each do |item|
          items_hash[item.name] = {
            "value" => item.value,
            "type" => item.type,
            "description" => item.description
          }.compact
        end

        environments = config.environments.each_with_object({}) do |(env_key, env_obj), out|
          out[env_key] = { "values" => env_obj.values_raw }
        end

        { "id" => config.id, "items" => items_hash, "environments" => environments }
      end
    end

    class FlagsNamespace
      def initialize(api_client)
        @api = SmplkitGeneratedClient::Flags::FlagsApi.new(api_client)
        @buffer = Management::FlagRegistrationBuffer.new
      end

      def register(declaration)
        @buffer.add(declaration)
        return unless @buffer.pending_count >= Management::FLAG_BATCH_FLUSH_SIZE

        begin
          flush
        rescue StandardError => e
          Smplkit.debug("registration", "threshold flag flush failed: #{e.class}: #{e.message}")
        end
      end

      # POST pending declarations to the bulk endpoint.
      #
      # Items remain in the buffer until the request succeeds, so a flush
      # against an unhealthy service is automatically retried by the next
      # +flush+ call (lazy +start+ retry, periodic background flush, or
      # final flush on close). Raises on failure — callers decide whether
      # to retry.
      def flush
        batch = @buffer.peek
        return if batch.empty?

        flag_items = batch.map do |entry|
          SmplkitGeneratedClient::Flags::FlagBulkItem.new(
            id: entry["id"], type: entry["type"], default: entry["default"],
            service: entry["service"], environment: entry["environment"]
          )
        end
        body = SmplkitGeneratedClient::Flags::FlagBulkRequest.new(flags: flag_items)
        ErrorMapping.call { @api.bulk_register_flags(body) }
        @buffer.commit(batch.map { |b| b["id"] })
      end

      def pending_count
        @buffer.pending_count
      end

      def list(page_number: nil, page_size: nil)
        opts = {}
        opts[:page_number] = page_number unless page_number.nil?
        opts[:page_size] = page_size unless page_size.nil?
        response = ErrorMapping.call { @api.list_flags(opts) }
        (response.data || []).map { |r| flag_from_resource(ResourceShim.from_model(r)) }
      end

      def get(id)
        response = ErrorMapping.call { @api.get_flag(id) }
        flag_from_resource(ResourceShim.from_model(response.data))
      end

      def delete(id)
        ErrorMapping.call { @api.delete_flag(id) }
        true
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
        response = ErrorMapping.call { @api.create_flag(flag_body(flag)) }
        flag_from_resource(ResourceShim.from_model(response.data))
      end

      def _update_flag(flag)
        response = ErrorMapping.call { @api.update_flag(flag.id, flag_body(flag)) }
        flag_from_resource(ResourceShim.from_model(response.data))
      end

      def fetch_flag(id)
        response = ErrorMapping.call { @api.get_flag(id) }
        Smplkit::Flags::Helpers.flag_dict_from_json(ResourceShim.from_model(response.data))
      end

      # Runtime entry — walks every page so an account holding more than
      # +RUNTIME_PAGE_SIZE+ flags still gets a complete in-memory store.
      def list_flags
        rows = PaginatedFetch.collect { |opts| @api.list_flags(opts) }
        rows.map { |r| Smplkit::Flags::Helpers.flag_dict_from_json(ResourceShim.from_model(r)) }
      end

      private

      def flag_body(flag)
        SmplkitGeneratedClient::Flags::FlagResponse.new(
          data: SmplkitGeneratedClient::Flags::FlagResource.new(
            type: "flag",
            id: flag.id,
            attributes: SmplkitGeneratedClient::Flags::Flag.new(
              name: flag.name,
              type: flag.type,
              default: flag.default,
              description: flag.description,
              values: flag_values_to_wire(flag.values),
              environments: flag_envs_to_wire(flag.environments)
            )
          )
        )
      end

      def flag_values_to_wire(values)
        return nil if values.nil?

        values.map do |v|
          SmplkitGeneratedClient::Flags::FlagValue.new(name: v.name, value: v.value)
        end
      end

      def flag_envs_to_wire(environments)
        return nil if environments.empty?

        environments.each_with_object({}) do |(env_key, env_obj), out|
          rules = env_obj.rules.map do |r|
            SmplkitGeneratedClient::Flags::FlagRule.new(
              logic: r.logic, value: r.value, description: r.description
            )
          end
          out[env_key] = SmplkitGeneratedClient::Flags::FlagEnvironment.new(
            enabled: env_obj.enabled, default: env_obj.default, rules: rules
          )
        end
      end

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
      def initialize(api_client)
        @api = SmplkitGeneratedClient::Logging::LoggersApi.new(api_client)
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

        items = batch.map do |entry|
          SmplkitGeneratedClient::Logging::LoggerBulkItem.new(
            id: entry["id"],
            resolved_level: entry["resolved_level"],
            level: entry["level"],
            service: entry["service"],
            environment: entry["environment"]
          )
        end
        body = SmplkitGeneratedClient::Logging::LoggerBulkRequest.new(loggers: items)
        ErrorMapping.call { @api.bulk_register_loggers(body) }
      rescue StandardError => e
        Smplkit.debug("registration", "logger flush failed: #{e.class}: #{e.message}")
      end

      def list(page_number: nil, page_size: nil)
        opts = {}
        opts[:page_number] = page_number unless page_number.nil?
        opts[:page_size] = page_size unless page_size.nil?
        response = ErrorMapping.call { @api.list_loggers(opts) }
        (response.data || []).map do |r|
          Smplkit::Logging::Helpers.logger_resource_to_model(self, ResourceShim.from_model(r))
        end
      end

      def get(id)
        normalized = Smplkit::Logging::Normalize.normalize_logger_name(id)
        response = ErrorMapping.call { @api.get_logger(normalized) }
        Smplkit::Logging::Helpers.logger_resource_to_model(self, ResourceShim.from_model(response.data))
      end

      def delete(id)
        normalized = Smplkit::Logging::Normalize.normalize_logger_name(id)
        ErrorMapping.call { @api.delete_logger(normalized) }
        true
      end

      def _update_logger(logger)
        response = ErrorMapping.call { @api.update_logger(logger.id || logger.name, logger_body(logger)) }
        Smplkit::Logging::Helpers.logger_resource_to_model(self, ResourceShim.from_model(response.data))
      end

      # Runtime entry — walks every page and returns an id-keyed Hash of
      # resolution-cache entries (+level+, +group+, +managed+,
      # +environments+). Mirrors the Python SDK's
      # +LoggingClient._fetch_and_apply+ loggers branch.
      def list_logger_entries
        rows = PaginatedFetch.collect { |opts| @api.list_loggers(opts) }
        rows.to_h { |r| logger_entry_from_resource(ResourceShim.from_model(r)) }
      end

      # Fetch one logger as a resolution-cache entry. Used by the
      # +logger_changed+ WS handler.
      def get_logger_entry(id)
        normalized = Smplkit::Logging::Normalize.normalize_logger_name(id)
        response = ErrorMapping.call { @api.get_logger(normalized) }
        logger_entry_from_resource(ResourceShim.from_model(response.data))
      end

      private

      def logger_entry_from_resource(resource)
        attrs = resource["attributes"] || {}
        [
          resource["id"],
          {
            "level" => attrs["level"],
            "group" => attrs["group"],
            "managed" => attrs.key?("managed") ? attrs["managed"] : true,
            "environments" => attrs["environments"] || {}
          }
        ]
      end

      def logger_body(logger)
        # Logger server schema: name, level, group, managed.
        # +resolved_level+ is read-only, +service+/+environment+ are
        # observed via bulk register, +description+ is wrapper-local.
        SmplkitGeneratedClient::Logging::LoggerResponse.new(
          data: SmplkitGeneratedClient::Logging::LoggerResource.new(
            type: "logger",
            id: logger.id,
            attributes: SmplkitGeneratedClient::Logging::Logger.new(
              name: logger.name,
              level: logger.level&.to_s,
              group: logger.log_group_id,
              managed: logger.managed
            )
          )
        )
      end
    end

    class LogGroupsNamespace
      def initialize(api_client)
        @api = SmplkitGeneratedClient::Logging::LogGroupsApi.new(api_client)
      end

      def list(page_number: nil, page_size: nil)
        opts = {}
        opts[:page_number] = page_number unless page_number.nil?
        opts[:page_size] = page_size unless page_size.nil?
        response = ErrorMapping.call { @api.list_log_groups(opts) }
        (response.data || []).map do |r|
          Smplkit::Logging::Helpers.log_group_resource_to_model(self, ResourceShim.from_model(r))
        end
      end

      def get(key)
        response = ErrorMapping.call { @api.get_log_group(key) }
        Smplkit::Logging::Helpers.log_group_resource_to_model(self, ResourceShim.from_model(response.data))
      end

      def delete(key)
        ErrorMapping.call { @api.delete_log_group(key) }
        true
      end

      def new_log_group(key, name: nil, level: nil, description: nil, parent: nil)
        Smplkit::Logging::SmplLogGroup.new(
          self, key: key, name: name || Smplkit::Helpers.key_to_display_name(key),
                level: level && Smplkit::LogLevel.coerce(level), description: description,
                parent_id: parent.is_a?(Smplkit::Logging::SmplLogGroup) ? parent.key : parent
        )
      end

      def _create_log_group(group)
        response = ErrorMapping.call { @api.create_log_group(log_group_body(group)) }
        Smplkit::Logging::Helpers.log_group_resource_to_model(self, ResourceShim.from_model(response.data))
      end

      def _update_log_group(group)
        response = ErrorMapping.call { @api.update_log_group(group.key, log_group_body(group)) }
        Smplkit::Logging::Helpers.log_group_resource_to_model(self, ResourceShim.from_model(response.data))
      end

      # Runtime entry — walks every page and returns an id-keyed Hash of
      # resolution-cache entries (+level+, +group+, +environments+). The
      # +group+ key carries the *parent group id* so the resolution
      # algorithm can walk the chain with the same key shape it uses for
      # loggers.
      def list_group_entries
        rows = PaginatedFetch.collect { |opts| @api.list_log_groups(opts) }
        rows.to_h { |r| group_entry_from_resource(ResourceShim.from_model(r)) }
      end

      def get_group_entry(key)
        response = ErrorMapping.call { @api.get_log_group(key) }
        group_entry_from_resource(ResourceShim.from_model(response.data))
      end

      private

      def group_entry_from_resource(resource)
        attrs = resource["attributes"] || {}
        [
          resource["id"],
          {
            "level" => attrs["level"],
            "group" => attrs["parent_id"],
            "environments" => attrs["environments"] || {}
          }
        ]
      end

      def log_group_body(group)
        # LogGroup server schema: name, level, parent_id (no description).
        SmplkitGeneratedClient::Logging::LogGroupResponse.new(
          data: SmplkitGeneratedClient::Logging::LogGroupResource.new(
            type: "log_group",
            id: group.key,
            attributes: SmplkitGeneratedClient::Logging::LogGroup.new(
              name: group.name,
              level: group.level&.to_s,
              parent_id: group.parent_id
            )
          )
        )
      end
    end
  end
end
