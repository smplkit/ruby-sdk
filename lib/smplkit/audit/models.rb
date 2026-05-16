# frozen_string_literal: true

module Smplkit
  module Audit
    # Parse the +page[after]+ cursor out of a JSON:API +links.next+
    # URL. Returns nil for non-string input or when the link carries
    # no cursor parameter; trims trailing query params at the next
    # ampersand so they don't leak into the token.
    # Wrap a generated-audit-API call and translate +ApiError+ into the
    # +Smplkit::Error+ hierarchy. Connection-level failures (no
    # response code) become {Smplkit::ConnectionError}; status-coded
    # failures route through {Smplkit::Errors.raise_for_status}, which
    # emits +PaymentRequiredError+ / +NotFoundError+ / +ConflictError+
    # / +ValidationError+ / +Error+ depending on the JSON:API body.
    def self.call_api
      yield
    rescue SmplkitGeneratedClient::Audit::ApiError => e
      raise Smplkit::ConnectionError, e.message.to_s if e.code.nil? || e.code.zero?

      Smplkit::Errors.raise_for_status(e.code, e.response_body.to_s)
      # raise_for_status only returns on 2xx; if we get here the
      # generated layer raised on a 2xx (shouldn't happen) — re-raise
      # the original so the caller can inspect.
      raise
    end

    def self.next_cursor(link)
      return nil unless link.is_a?(String)

      idx = link.index("page[after]=")
      return nil if idx.nil?

      token = link[(idx + "page[after]=".length)..]
      amp = token.index("&")
      amp ? token[0...amp] : token
    end

    # Pull the offset-pagination block out of a JSON:API +meta+ envelope.
    # Returns a hash with +:page+/+:size+ (and +:total+/+:total_pages+ when
    # the request opted into +meta[total]=true+). Always returns a hash so
    # callers don't have to nil-check before reading individual keys.
    def self.extract_pagination(meta)
      pagination = meta&.pagination
      return {} if pagination.nil?

      out = { page: pagination.page, size: pagination.size }
      out[:total] = pagination.total unless pagination.total.nil?
      out[:total_pages] = pagination.total_pages unless pagination.total_pages.nil?
      out
    end

    # Public-facing enum for SIEM streaming destination types.
    #
    # Mirrors the +ForwarderType+ enum the audit OpenAPI spec emits
    # (ADR-047 §2.12). Customers pass these constants — or any string
    # in {VALUES} — to the management +forwarders+ surface. The wrapper
    # validates membership before round-tripping to the wire.
    module ForwarderType
      HTTP = "HTTP"
      DATADOG = "DATADOG"
      SPLUNK_HEC = "SPLUNK_HEC"
      SUMO_LOGIC = "SUMO_LOGIC"
      NEW_RELIC = "NEW_RELIC"
      HONEYCOMB = "HONEYCOMB"
      ELASTIC = "ELASTIC"

      VALUES = [HTTP, DATADOG, SPLUNK_HEC, SUMO_LOGIC, NEW_RELIC, HONEYCOMB, ELASTIC].freeze

      def self.coerce(value)
        return nil if value.nil?

        s = value.to_s
        return s if VALUES.include?(s)

        raise ArgumentError,
              "Unknown ForwarderType #{value.inspect}; expected one of #{VALUES.inspect}"
      end
    end

    # Public-facing audit event resource. ADR-047 §2.3.1.
    AuditEvent = Struct.new(
      :id, :action, :resource_type, :resource_id,
      :occurred_at, :created_at,
      :actor_type, :actor_id, :actor_label,
      :data, :idempotency_key, :do_not_forward,
      keyword_init: true
    ) do
      def self.from_resource(resource)
        attrs = resource.attributes
        new(
          id: resource.id,
          action: attrs.action,
          resource_type: attrs.resource_type,
          resource_id: attrs.resource_id,
          occurred_at: attrs.occurred_at,
          created_at: attrs.created_at,
          actor_type: attrs.actor_type,
          actor_id: attrs.actor_id,
          actor_label: attrs.actor_label,
          data: Smplkit::Helpers.deep_stringify_keys(attrs.data || {}),
          idempotency_key: attrs.idempotency_key,
          do_not_forward: attrs.do_not_forward || false
        )
      end
    end

    # A distinct +resource_type+ slug seen for the account.
    #
    # The +id+ and +resource_type+ are the same value — JSON:API surfaces
    # the customer-facing key as the resource id (ADR-014). The duplication
    # keeps SDK consumers from having to dig into the id field when
    # filtering UI controls; pick whichever name reads better in context.
    ResourceType = Struct.new(:id, :resource_type, :created_at, keyword_init: true) do
      def self.from_resource(resource)
        attrs = resource.attributes
        new(
          id: resource.id,
          resource_type: attrs.resource_type || resource.id,
          created_at: attrs.created_at
        )
      end
    end

    # A distinct +action+ slug seen for the account.
    #
    # Same shape as {ResourceType} — +id+ and +action+ are the same value.
    # +created_at+ is the earliest sighting; when the parent list call
    # filtered by +resource_type+, this is the first sighting of that
    # specific (action, resource_type) triple, not the action overall.
    Action = Struct.new(:id, :action, :created_at, keyword_init: true) do
      def self.from_resource(resource)
        attrs = resource.attributes
        new(
          id: resource.id,
          action: attrs.action || resource.id,
          created_at: attrs.created_at
        )
      end
    end

    HttpHeader = Struct.new(:name, :value, keyword_init: true)

    # rubocop:disable Lint/StructNewOverride -- ``:method`` matches the
    # API attribute and shadowing Struct#method is the expected ergonomics.
    HttpConfiguration = Struct.new(:method, :url, :headers, :success_status, keyword_init: true) do
      def initialize(method: "POST", url: "", headers: nil, success_status: "2xx")
        super(method: method, url: url, headers: headers || [], success_status: success_status)
      end

      def self.to_wire(src)
        h = src.is_a?(Hash) ? new(**src) : src
        SmplkitGeneratedClient::Audit::HttpConfiguration.new(
          method: h.method,
          url: h.url,
          headers: (h.headers || []).map do |hdr|
            name, value = if hdr.is_a?(Hash)
                            [hdr[:name] || hdr["name"],
                             hdr[:value] || hdr["value"]]
                          else
                            [hdr.name, hdr.value]
                          end
            SmplkitGeneratedClient::Audit::HttpHeader.new(name: name, value: value)
          end,
          success_status: h.success_status
        )
      end

      def self.from_wire(src)
        return new if src.nil?

        new(
          method: src.method || "POST",
          url: src.url || "",
          headers: (src.headers || []).map { |h| HttpHeader.new(name: h.name, value: h.value) },
          success_status: src.success_status || "2xx"
        )
      end
    end
    # rubocop:enable Lint/StructNewOverride

    # rubocop:disable Lint/StructNewOverride -- ``:filter`` matches the
    # API attribute and shadowing Struct#filter is the expected ergonomics.
    Forwarder = Struct.new(
      :id, :name, :description, :forwarder_type, :enabled,
      :filter, :transform_type, :transform, :configuration,
      :created_at, :updated_at, :deleted_at, :version,
      keyword_init: true
    ) do
      def self.from_resource(resource)
        a = resource.attributes
        new(
          id: resource.id,
          name: a.name,
          description: a.description,
          forwarder_type: a.forwarder_type,
          enabled: a.enabled.nil? || a.enabled,
          filter: a.filter.nil? ? nil : Smplkit::Helpers.deep_stringify_keys(a.filter),
          transform_type: a.transform_type,
          transform: a.transform,
          configuration: HttpConfiguration.from_wire(a.configuration),
          created_at: a.created_at,
          updated_at: a.updated_at,
          deleted_at: a.deleted_at,
          version: a.version
        )
      end
    end
    # rubocop:enable Lint/StructNewOverride
  end
end
