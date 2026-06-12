# frozen_string_literal: true

# The Smpl Platform client — cross-cutting CRUD on +client.platform+.
#
# +PlatformClient+ groups the account-wide configuration resources that aren't
# owned by a single product, mirroring the product UI's Platform area:
#
# - +platform.environments+ — environment CRUD
# - +platform.services+ — service CRUD
# - +platform.contexts+ — evaluation-context registration + read/delete
# - +platform.context_types+ — context-type CRUD
#
# All four are pure CRUD — no +install+ gate. Every sub-client speaks to the
# app service, so the client needs exactly one app transport (plus the
# context-registration buffer that +contexts+ drains).
#
# The client supports two construction shapes:
#
# * *Wired* into +Smplkit::Client+ — borrows the parent's app transport and an
#   externally-supplied context buffer. This is the common path;
#   +client.flags+ borrows +client.platform.contexts+ as its evaluation-context
#   registration seam.
# * *Standalone* — +PlatformClient.new(api_key: ..., base_url: ..., ...)+ builds
#   and owns its own app transport and buffer. +close+ tears down only the
#   owned transport.
module Smplkit
  module Platform
    # Resolve the two-arg or composite-id form to +[type, key]+.
    def self.split_context_id(id_or_type, key)
      return [id_or_type, key] unless key.nil?

      unless id_or_type.include?(":")
        raise ArgumentError,
              "context id must be 'type:key' (got #{id_or_type.inspect}); " \
              "alternatively pass type and key as separate args"
      end

      id_or_type.split(":", 2)
    end

    # Build a standalone app transport from resolved config.
    #
    # +base_url+/+api_key+ are used directly when supplied (the path the
    # top-level client takes after it has already resolved them); otherwise the
    # management config resolver fills in whatever is missing (+~/.smplkit+ /
    # env vars / defaults).
    def self.app_transport(api_key:, base_url:, profile:, base_domain:, scheme:, debug:, extra_headers:)
      cfg = ConfigResolution.resolve_management_config(
        profile: profile, api_key: api_key, base_domain: base_domain, scheme: scheme, debug: debug
      )
      resolved_key = api_key.nil? ? cfg.api_key : api_key
      merged = {}
      merged.merge!(cfg.extra_headers || {})
      merged.merge!(extra_headers || {})
      tcfg = ConfigResolution::ResolvedManagementConfig.new(
        api_key: resolved_key, base_domain: cfg.base_domain, scheme: cfg.scheme,
        debug: cfg.debug, extra_headers: merged
      )
      Transport.build_api_client(SmplkitGeneratedClient::App, "app", tcfg, base_url: base_url)
    end

    # -----------------------------------------------------------------------
    # Environments
    # -----------------------------------------------------------------------

    # Sync environment CRUD (+client.platform.environments+).
    class EnvironmentsClient
      def initialize(app_http)
        @api = SmplkitGeneratedClient::App::EnvironmentsApi.new(app_http)
      end

      # Return an unsaved +Environment+. Call +.save+ to persist.
      def new(id, name:, color: nil, classification: EnvironmentClassification::STANDARD)
        Environment.new(self, id: id, name: name, color: color, classification: classification)
      end

      def list(page_number: nil, page_size: nil)
        opts = {}
        opts[:page_number] = page_number unless page_number.nil?
        opts[:page_size] = page_size unless page_size.nil?
        response = ApiSupport::ErrorMapping.call { @api.list_environments(opts) }
        (response.data || []).map { |r| from_resource(ApiSupport::ResourceShim.from_model(r)) }
      end

      def get(id)
        response = ApiSupport::ErrorMapping.call { @api.get_environment(id) }
        from_resource(ApiSupport::ResourceShim.from_model(response.data))
      end

      def delete(id)
        ApiSupport::ErrorMapping.call { @api.delete_environment(id) }
        nil
      end

      def _create(env)
        response = ApiSupport::ErrorMapping.call { @api.create_environment(body_for(env)) }
        from_resource(ApiSupport::ResourceShim.from_model(response.data))
      end

      def _update(env)
        raise "cannot update an Environment with no id" if env.id.nil?

        response = ApiSupport::ErrorMapping.call { @api.update_environment(env.id, body_for(env)) }
        from_resource(ApiSupport::ResourceShim.from_model(response.data))
      end

      private

      def body_for(env)
        SmplkitGeneratedClient::App::EnvironmentRequest.new(
          data: SmplkitGeneratedClient::App::EnvironmentResource.new(
            type: "environment",
            id: env.id,
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
        classification =
          attrs["classification"] == "AD_HOC" ? EnvironmentClassification::AD_HOC : EnvironmentClassification::STANDARD
        Environment.new(
          self,
          id: resource["id"], name: attrs["name"], color: attrs["color"],
          classification: classification,
          created_at: attrs["created_at"], updated_at: attrs["updated_at"]
        )
      end
    end

    # -----------------------------------------------------------------------
    # Services
    # -----------------------------------------------------------------------

    # Sync service CRUD (+client.platform.services+).
    class ServicesClient
      def initialize(app_http)
        @api = SmplkitGeneratedClient::App::ServicesApi.new(app_http)
      end

      # Return an unsaved +Service+. Call +.save+ to persist.
      def new(id, name:)
        Service.new(self, id: id, name: name)
      end

      def list(page_number: nil, page_size: nil)
        opts = {}
        opts[:page_number] = page_number unless page_number.nil?
        opts[:page_size] = page_size unless page_size.nil?
        response = ApiSupport::ErrorMapping.call { @api.list_services(opts) }
        (response.data || []).map { |r| from_resource(ApiSupport::ResourceShim.from_model(r)) }
      end

      def get(id)
        response = ApiSupport::ErrorMapping.call { @api.get_service(id) }
        from_resource(ApiSupport::ResourceShim.from_model(response.data))
      end

      def delete(id)
        ApiSupport::ErrorMapping.call { @api.delete_service(id) }
        nil
      end

      def _create(svc)
        response = ApiSupport::ErrorMapping.call { @api.create_service(create_body_for(svc)) }
        from_resource(ApiSupport::ResourceShim.from_model(response.data))
      end

      def _update(svc)
        raise "cannot update a Service with no id" if svc.id.nil?

        response = ApiSupport::ErrorMapping.call { @api.update_service(svc.id, body_for(svc)) }
        from_resource(ApiSupport::ResourceShim.from_model(response.data))
      end

      private

      def body_for(svc)
        SmplkitGeneratedClient::App::ServiceRequest.new(
          data: SmplkitGeneratedClient::App::ServiceResource.new(
            type: "service",
            id: svc.id,
            attributes: SmplkitGeneratedClient::App::Service.new(name: svc.name)
          )
        )
      end

      def create_body_for(svc)
        SmplkitGeneratedClient::App::ServiceCreateRequest.new(
          data: SmplkitGeneratedClient::App::ServiceCreateResource.new(
            type: "service",
            id: svc.id,
            attributes: SmplkitGeneratedClient::App::Service.new(name: svc.name)
          )
        )
      end

      def from_resource(resource)
        attrs = resource["attributes"] || {}
        Service.new(
          self,
          id: resource["id"], name: attrs["name"],
          created_at: attrs["created_at"], updated_at: attrs["updated_at"]
        )
      end
    end

    # -----------------------------------------------------------------------
    # Context Types
    # -----------------------------------------------------------------------

    # Sync context-type CRUD (+client.platform.context_types+).
    class ContextTypesClient
      def initialize(app_http)
        @api = SmplkitGeneratedClient::App::ContextTypesApi.new(app_http)
      end

      def new(id, name: nil, attributes: nil)
        ContextType.new(self, id: id, name: name || id, attributes: attributes || {})
      end

      def list(page_number: nil, page_size: nil)
        opts = {}
        opts[:page_number] = page_number unless page_number.nil?
        opts[:page_size] = page_size unless page_size.nil?
        response = ApiSupport::ErrorMapping.call { @api.list_context_types(opts) }
        (response.data || []).map { |r| from_resource(ApiSupport::ResourceShim.from_model(r)) }
      end

      def get(id)
        response = ApiSupport::ErrorMapping.call { @api.get_context_type(id) }
        from_resource(ApiSupport::ResourceShim.from_model(response.data))
      end

      def delete(id)
        ApiSupport::ErrorMapping.call { @api.delete_context_type(id) }
        nil
      end

      def _create(ct)
        response = ApiSupport::ErrorMapping.call { @api.create_context_type(body_for(ct)) }
        from_resource(ApiSupport::ResourceShim.from_model(response.data))
      end

      def _update(ct)
        raise "cannot update a ContextType with no id" if ct.id.nil?

        response = ApiSupport::ErrorMapping.call { @api.update_context_type(ct.id, body_for(ct)) }
        from_resource(ApiSupport::ResourceShim.from_model(response.data))
      end

      private

      def body_for(ct)
        SmplkitGeneratedClient::App::ContextTypeRequest.new(
          data: SmplkitGeneratedClient::App::ContextTypeResource.new(
            type: "context_type",
            id: ct.id,
            attributes: SmplkitGeneratedClient::App::ContextType.new(name: ct.name, attributes: ct.attributes)
          )
        )
      end

      def from_resource(resource)
        attrs = resource["attributes"] || {}
        raw_meta = attrs["attributes"]
        attribute_metadata = raw_meta.is_a?(Hash) ? raw_meta : {}
        ContextType.new(
          self,
          id: resource["id"], name: attrs["name"], attributes: attribute_metadata,
          created_at: attrs["created_at"], updated_at: attrs["updated_at"]
        )
      end
    end

    # -----------------------------------------------------------------------
    # Contexts
    # -----------------------------------------------------------------------

    # Sync context registration + read/delete (+client.platform.contexts+).
    class ContextsClient
      def initialize(app_http, buffer)
        @api = SmplkitGeneratedClient::App::ContextsApi.new(app_http)
        @buffer = buffer
      end

      # Buffer contexts for registration; optionally flush immediately.
      def register(items, flush: false)
        batch = items.is_a?(Array) ? items : [items]
        @buffer.observe(batch)
        if flush
          self.flush
          return
        end
        return unless @buffer.pending_count >= CONTEXT_BATCH_FLUSH_SIZE

        Thread.new { threshold_flush }
      end

      # Send any pending observations to the server.
      def flush
        batch = @buffer.drain
        return if batch.empty?

        body = build_bulk_register_body(batch)
        ApiSupport::ErrorMapping.call { @api.bulk_register_contexts(body) }
      end

      # Number of observations queued and awaiting flush.
      def pending_count
        @buffer.pending_count
      end

      # List all contexts of a given type.
      def list(type, page_number: nil, page_size: nil)
        opts = { filter_context_type: type }
        opts[:page_number] = page_number unless page_number.nil?
        opts[:page_size] = page_size unless page_size.nil?
        response = ApiSupport::ErrorMapping.call { @api.list_contexts(opts) }
        (response.data || []).map { |r| context_from_resource(ApiSupport::ResourceShim.from_model(r)) }
      end

      def get(id_or_type, key = nil)
        ctx_type, ctx_key = Platform.split_context_id(id_or_type, key)
        response = ApiSupport::ErrorMapping.call { @api.get_context("#{ctx_type}:#{ctx_key}") }
        context_from_resource(ApiSupport::ResourceShim.from_model(response.data))
      end

      def delete(id_or_type, key = nil)
        ctx_type, ctx_key = Platform.split_context_id(id_or_type, key)
        ApiSupport::ErrorMapping.call { @api.delete_context("#{ctx_type}:#{ctx_key}") }
        nil
      end

      def _save_context(ctx)
        body = ctx_to_resource(ctx)
        response = ApiSupport::ErrorMapping.call { @api.update_context(ctx.id, body) }
        context_from_resource(ApiSupport::ResourceShim.from_model(response.data))
      end

      private

      def threshold_flush
        flush
      rescue StandardError => e
        Smplkit.debug("registration", "context registration flush failed: #{e.class}: #{e.message}")
      end

      def build_bulk_register_body(items)
        bulk = items.map do |item|
          SmplkitGeneratedClient::App::ContextBulkItem.new(
            type: item["type"], key: item["key"], attributes: item["attributes"] || {}
          )
        end
        SmplkitGeneratedClient::App::ContextBulkRegister.new(contexts: bulk)
      end

      def ctx_to_resource(ctx)
        SmplkitGeneratedClient::App::ContextResponse.new(
          data: SmplkitGeneratedClient::App::ContextResource.new(
            type: "context",
            id: ctx.id,
            attributes: SmplkitGeneratedClient::App::Context.new(
              name: ctx.name, context_type: ctx.type, attributes: ctx.attributes
            )
          )
        )
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

    # -----------------------------------------------------------------------
    # PlatformClient (client.platform)
    # -----------------------------------------------------------------------

    # The Smpl Platform client (sync).
    #
    # Groups the account-wide CRUD resources that aren't owned by a single
    # product, reachable as +client.platform+ (+Smplkit::Client+) or
    # constructed directly:
    #
    #   platform = Smplkit::PlatformClient.new(api_key: "sk_...")
    #   prod = platform.environments.new("production", name: "Production")
    #   prod.save
    #   platform.services.list.each { |svc| ... }
    #
    # Sub-clients: +environments+, +services+, +contexts+, +context_types+.
    # Pure CRUD — no +install+ required.
    #
    # @param api_key [String, nil] API key. When omitted, resolved from
    #   +SMPLKIT_API_KEY+ or +~/.smplkit+.
    # @param base_url [String, nil] Full app-service base URL. Usually resolved
    #   from +base_domain+/+scheme+; supplied directly by the top-level clients
    #   which have already computed it.
    # @param profile [String, nil] Named +~/.smplkit+ profile section.
    # @param base_domain [String, nil] Base domain for API requests (default
    #   +"smplkit.com"+).
    # @param scheme [String, nil] URL scheme (default +"https"+).
    # @param debug [Boolean, nil] Enable SDK debug logging.
    # @param extra_headers [Hash, nil] Extra headers attached to every request.
    # @param app_transport Internal — a pre-built app transport supplied by a
    #   top-level client so the platform surface shares one connection pool.
    #   Not for direct use.
    # @param context_buffer Internal — the shared context-registration buffer.
    #   Not for direct use.
    class PlatformClient
      attr_reader :environments, :services, :contexts, :context_types

      def initialize(api_key: nil, base_url: nil, profile: nil, base_domain: nil,
                     scheme: nil, debug: nil, extra_headers: nil,
                     app_transport: nil, context_buffer: nil)
        if app_transport.nil?
          @app_http = Platform.app_transport(
            api_key: api_key, base_url: base_url, profile: profile,
            base_domain: base_domain, scheme: scheme, debug: debug, extra_headers: extra_headers
          )
          @owns_transport = true
        else
          @app_http = app_transport
          @owns_transport = false
        end

        buffer = context_buffer || ContextRegistrationBuffer.new
        @context_buffer = buffer

        @environments = EnvironmentsClient.new(@app_http)
        @services = ServicesClient.new(@app_http)
        @contexts = ContextsClient.new(@app_http, buffer)
        @context_types = ContextTypesClient.new(@app_http)
      end

      # Close the app transport — only when this client owns it.
      #
      # A wired client borrows the parent's app transport and closes nothing.
      def close
        return unless @owns_transport

        # The generated ApiClient owns Faraday connections that release on GC;
        # there is no explicit shutdown to call.
        nil
      end

      # Construct, yield to the block, and close on exit.
      def self.open(**kwargs)
        client = new(**kwargs)
        begin
          yield client
        ensure
          client.close
        end
      end
    end
  end

  PlatformClient = Platform::PlatformClient
end
