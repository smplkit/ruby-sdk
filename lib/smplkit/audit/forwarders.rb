# frozen_string_literal: true

module Smplkit
  module Audit
    # SIEM streaming forwarders for the authenticated account.
    #
    # Pro tier only — every method here raises a wrapped 402
    # +SmplkitGeneratedClient::Audit::ApiError+ on lower tiers.
    class Forwarders
      attr_reader :deliveries, :actions

      def initialize(api)
        @api = api
        @deliveries = ForwarderDeliveries.new(api)
        @actions = ForwarderActions.new(api)
      end

      def create(name:, forwarder_type:, http:, enabled: true,
                 filter: nil, transform: nil, data: nil)
        body = wrap_forwarder(nil, name, forwarder_type, http, enabled, filter, transform, data)
        resp = @api.create_forwarder(body)
        Forwarder.from_resource(resp.data)
      end

      def list(forwarder_type: nil, enabled: nil, page_size: nil, page_after: nil)
        opts = {}
        opts[:filter_forwarder_type] = forwarder_type if forwarder_type
        opts[:filter_enabled] = enabled unless enabled.nil?
        opts[:page_size] = page_size if page_size
        opts[:page_after] = page_after if page_after
        resp = @api.list_forwarders(opts)
        forwarders = (resp.data || []).map { |r| Forwarder.from_resource(r) }
        ListForwardersPage.new(forwarders, Forwarders.next_cursor(resp.links&._next))
      end

      def get(forwarder_id)
        resp = @api.get_forwarder(forwarder_id)
        Forwarder.from_resource(resp.data)
      end

      def update(forwarder_id, name:, forwarder_type:, http:, enabled: true,
                 filter: nil, transform: nil, data: nil)
        body = wrap_forwarder(forwarder_id, name, forwarder_type, http, enabled, filter, transform, data)
        resp = @api.update_forwarder(forwarder_id, body)
        Forwarder.from_resource(resp.data)
      end

      def delete(forwarder_id)
        @api.delete_forwarder(forwarder_id)
        nil
      end

      def self.next_cursor(link)
        return nil unless link.is_a?(String)

        idx = link.index("page[after]=")
        return nil if idx.nil?

        token = link[(idx + "page[after]=".length)..]
        amp = token.index("&")
        amp ? token[0...amp] : token
      end

      private

      def wrap_forwarder(id, name, forwarder_type, http, enabled, filter, transform, data)
        attrs = SmplkitGeneratedClient::Audit::Forwarder.new(
          name: name,
          forwarder_type: forwarder_type,
          enabled: enabled,
          # Server-side validation rejects ``data: null`` (the field is
          # required-non-null in the OpenAPI schema). Default to an empty
          # hash mirroring the AuditEvents.record fix.
          data: data || {},
          http: ForwarderHttp.to_wire(http),
          filter: filter,
          transform: transform
        )
        resource = SmplkitGeneratedClient::Audit::ForwarderResource.new(
          id: id ? id.to_s : "",
          type: "forwarder",
          attributes: attrs
        )
        SmplkitGeneratedClient::Audit::ForwarderResponse.new(data: resource)
      end
    end

    # Sub-namespace for the per-forwarder delivery log + per-delivery retry.
    class ForwarderDeliveries
      attr_reader :actions

      def initialize(api)
        @api = api
        @actions = DeliveryActions.new(api)
      end

      def list(forwarder_id, status: nil, created_at_range: nil, page_size: nil, page_after: nil)
        opts = {}
        opts[:filter_status] = status if status
        opts[:filter_created_at] = created_at_range if created_at_range
        opts[:page_size] = page_size if page_size
        opts[:page_after] = page_after if page_after
        resp = @api.list_forwarder_deliveries(forwarder_id, opts)
        deliveries = (resp.data || []).map { |r| ForwarderDelivery.from_resource(r) }
        ListDeliveriesPage.new(deliveries, Forwarders.next_cursor(resp.links&._next))
      end
    end

    # +client.audit.forwarders.deliveries.actions.retry(forwarder_id, delivery_id)+
    class DeliveryActions
      def initialize(api)
        @api = api
      end

      def retry(forwarder_id, delivery_id)
        resp = @api.retry_forwarder_delivery(forwarder_id, delivery_id)
        ForwarderDelivery.from_resource(resp.data)
      end
    end

    # +client.audit.forwarders.actions.retry_failed_deliveries(forwarder_id)+
    class ForwarderActions
      def initialize(api)
        @api = api
      end

      def retry_failed_deliveries(forwarder_id)
        resp = @api.retry_failed_forwarder_deliveries(forwarder_id)
        RetryFailedDeliveriesSummary.new(
          attempted: resp.attempted,
          succeeded: resp.succeeded,
          failed: resp.failed
        )
      end
    end

    # ----------------------------------------------------------------------
    # Public-facing model structs
    # ----------------------------------------------------------------------

    HttpHeader = Struct.new(:name, :value, keyword_init: true)

    ForwarderHttp = Struct.new(:method, :url, :headers, :body, :success_status, keyword_init: true) do
      def initialize(method: "POST", url: "", headers: nil, body: nil, success_status: "2xx")
        super(method: method, url: url, headers: headers || [], body: body, success_status: success_status)
      end

      def self.to_wire(src)
        h = src.is_a?(Hash) ? new(**src) : src
        SmplkitGeneratedClient::Audit::ForwarderHttp.new(
          method: h.method,
          url: h.url,
          headers: (h.headers || []).map do |hdr|
            name, value = hdr.is_a?(Hash) ? [hdr[:name] || hdr["name"],
                                             hdr[:value] || hdr["value"]] : [hdr.name, hdr.value]
            SmplkitGeneratedClient::Audit::HttpHeader.new(name: name, value: value)
          end,
          body: h.body,
          success_status: h.success_status
        )
      end

      def self.from_wire(src)
        return new if src.nil?

        new(
          method: src.method || "POST",
          url: src.url || "",
          headers: (src.headers || []).map { |h| HttpHeader.new(name: h.name, value: h.value) },
          body: src.body,
          success_status: src.success_status || "2xx"
        )
      end
    end

    Forwarder = Struct.new(
      :id, :name, :slug, :forwarder_type, :enabled,
      :filter, :transform, :http, :data,
      :created_at, :updated_at, :deleted_at, :version,
      keyword_init: true
    ) do
      def self.from_resource(resource)
        a = resource.attributes
        new(
          id: resource.id,
          name: a.name,
          slug: a.slug,
          forwarder_type: a.forwarder_type,
          enabled: a.enabled.nil? ? true : a.enabled,
          filter: a.filter,
          transform: a.transform,
          http: ForwarderHttp.from_wire(a.http),
          data: a.data || {},
          created_at: a.created_at,
          updated_at: a.updated_at,
          deleted_at: a.deleted_at,
          version: a.version
        )
      end
    end

    ListForwardersPage = Struct.new(:forwarders, :next_cursor)

    ForwarderDelivery = Struct.new(
      :id, :forwarder_id, :event_id, :attempt_number, :status,
      :request, :response_status, :response_body, :latency_ms, :error, :created_at,
      keyword_init: true
    ) do
      def self.from_resource(resource)
        a = resource.attributes
        new(
          id: resource.id,
          forwarder_id: a.forwarder_id,
          event_id: a.event_id,
          attempt_number: a.attempt_number,
          status: a.status,
          request: a.request,
          response_status: a.response_status,
          response_body: a.response_body,
          latency_ms: a.latency_ms,
          error: a.error,
          created_at: a.created_at
        )
      end
    end

    ListDeliveriesPage = Struct.new(:deliveries, :next_cursor)

    RetryFailedDeliveriesSummary = Struct.new(:attempted, :succeeded, :failed, keyword_init: true)

    TestForwarderResult = Struct.new(
      :succeeded, :response_status, :response_headers, :response_body, :latency_ms, :error,
      keyword_init: true
    )
  end
end
