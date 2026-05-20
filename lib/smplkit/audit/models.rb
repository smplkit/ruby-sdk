# frozen_string_literal: true

module Smplkit
  module Audit
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

    # Parse the +page[after]+ cursor out of a JSON:API +links.next+
    # URL. Returns nil for non-string input or when the link carries
    # no cursor parameter; trims trailing query params at the next
    # ampersand so they don't leak into the token.
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

    # Supported SIEM forwarder destination types (ADR-047 §2.12).
    #
    # Members are declared in alphabetical order. Customers pass these
    # constants — or the equivalent string — to the management
    # +forwarders+ surface; the wrapper validates membership via {coerce}
    # before round-tripping to the wire.
    module ForwarderType
      DATADOG = "datadog"
      ELASTIC = "elastic"
      HONEYCOMB = "honeycomb"
      HTTP = "http"
      NEW_RELIC = "new_relic"
      SPLUNK_HEC = "splunk_hec"
      SUMO_LOGIC = "sumo_logic"

      VALUES = [DATADOG, ELASTIC, HONEYCOMB, HTTP, NEW_RELIC, SPLUNK_HEC, SUMO_LOGIC].freeze

      # Validate and normalize an input to a wire-format string.
      #
      # @param value [String, nil] a published constant or its literal string.
      # @return [String, nil] the canonical wire value (or +nil+ when input is +nil+).
      # @raise [ArgumentError] when +value+ is not a member of {VALUES}.
      def self.coerce(value)
        return nil if value.nil?

        s = value.to_s
        return s if VALUES.include?(s)

        raise ArgumentError,
              "Unknown ForwarderType #{value.inspect}; expected one of #{VALUES.inspect}"
      end
    end

    # HTTP verb used by a forwarder's outbound delivery (ADR-047 §2.12).
    #
    # Mirrors the audit spec's +HttpConfigurationMethod+ enum so the
    # +HttpConfiguration#method+ field is constrained to a known value
    # instead of accepting any string. Members are declared in
    # alphabetical order.
    module HttpMethod
      DELETE = "DELETE"
      GET = "GET"
      PATCH = "PATCH"
      POST = "POST"
      PUT = "PUT"

      VALUES = [DELETE, GET, PATCH, POST, PUT].freeze

      # Validate and normalize an input to a wire-format string.
      #
      # @param value [String, nil] a published constant or its literal string.
      # @return [String, nil] the canonical wire value (or +nil+ when input is +nil+).
      # @raise [ArgumentError] when +value+ is not a member of {VALUES}.
      def self.coerce(value)
        return nil if value.nil?

        s = value.to_s
        return s if VALUES.include?(s)

        raise ArgumentError,
              "Unknown HttpMethod #{value.inspect}; expected one of #{VALUES.inspect}"
      end
    end

    # Engine that evaluates a forwarder's +transform+ template
    # (ADR-047 §2.12). Only +JSONATA+ is supported today; the enum
    # exists so the field is typed instead of accepting any string,
    # and so additional engines can be added without breaking the
    # public surface.
    module TransformType
      JSONATA = "JSONATA"

      VALUES = [JSONATA].freeze

      # Validate and normalize an input to a wire-format string.
      #
      # @param value [String, nil] a published constant or its literal string.
      # @return [String, nil] the canonical wire value (or +nil+ when input is +nil+).
      # @raise [ArgumentError] when +value+ is not a member of {VALUES}.
      def self.coerce(value)
        return nil if value.nil?

        s = value.to_s
        return s if VALUES.include?(s)

        raise ArgumentError,
              "Unknown TransformType #{value.inspect}; expected one of #{VALUES.inspect}"
      end
    end

    # A single audit event as returned by the audit service (ADR-047 §2.3.1).
    #
    # @!attribute [rw] id
    #   @return [String] Server-assigned UUID for this event.
    # @!attribute [rw] event_type
    #   @return [String] Event type slug — e.g. +"user.created"+, +"invoice.paid"+.
    # @!attribute [rw] resource_type
    #   @return [String] Type of resource the event operated on — e.g. +"invoice"+.
    # @!attribute [rw] resource_id
    #   @return [String] Customer-facing id of the resource the event operated on.
    # @!attribute [rw] occurred_at
    #   @return [String] ISO-8601 timestamp of when the event happened, as reported by the source.
    # @!attribute [rw] created_at
    #   @return [String] ISO-8601 timestamp of when the audit service first ingested this event.
    # @!attribute [rw] actor_type
    #   @return [String, nil] Customer-supplied free-form actor type string — +nil+ when not provided.
    # @!attribute [rw] actor_id
    #   @return [String, nil] Customer-supplied free-form actor identifier — +nil+ when not provided.
    # @!attribute [rw] actor_label
    #   @return [String, nil] Customer-supplied display label for the actor — typically a name or email.
    # @!attribute [rw] data
    #   @return [Hash{String => Object}] Free-form per-event payload defined by the customer.
    # @!attribute [rw] idempotency_key
    #   @return [String, nil] Customer-supplied dedupe key, +nil+ if not provided.
    # @!attribute [rw] do_not_forward
    #   @return [Boolean] When +true+, skip SIEM forwarder delivery regardless of any matching filter.
    AuditEvent = Struct.new(
      :id, :event_type, :resource_type, :resource_id,
      :occurred_at, :created_at,
      :actor_type, :actor_id, :actor_label,
      :data, :idempotency_key, :do_not_forward,
      keyword_init: true
    ) do
      def self.from_resource(resource)
        attrs = resource.attributes
        new(
          id: resource.id,
          event_type: attrs.event_type,
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
    #
    # @!attribute [rw] id
    #   @return [String] JSON:API resource id (same as +resource_type+).
    # @!attribute [rw] resource_type
    #   @return [String] The distinct resource_type slug.
    # @!attribute [rw] created_at
    #   @return [String] ISO-8601 timestamp of the earliest sighting for this slug.
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

    # A distinct +event_type+ slug seen for the account.
    #
    # Same shape as {ResourceType} — +id+ and +event_type+ are the same value.
    # +created_at+ is the earliest sighting; when the parent list call
    # filtered by +resource_type+, this is the first sighting of that
    # specific (event_type, resource_type) triple, not the event type overall.
    #
    # @!attribute [rw] id
    #   @return [String] JSON:API resource id (same as +event_type+).
    # @!attribute [rw] event_type
    #   @return [String] The distinct event type slug.
    # @!attribute [rw] created_at
    #   @return [String] ISO-8601 timestamp of the earliest sighting for this slug.
    EventType = Struct.new(:id, :event_type, :created_at, keyword_init: true) do
      def self.from_resource(resource)
        attrs = resource.attributes
        new(
          id: resource.id,
          event_type: attrs.event_type || resource.id,
          created_at: attrs.created_at
        )
      end
    end

    # A single name/value HTTP header on a forwarder destination.
    #
    # @!attribute [rw] name
    #   @return [String] Header name (e.g. +"Authorization"+, +"DD-API-KEY"+).
    # @!attribute [rw] value
    #   @return [String] Header value, plaintext on writes. The audit service
    #     encrypts values at rest; reads return them as +"<redacted>"+.
    HttpHeader = Struct.new(:name, :value, keyword_init: true)

    # Forwarder destination HTTP request shape.
    #
    # @!attribute [rw] method
    #   @return [String] HTTP verb used for delivery. Defaults to {HttpMethod::POST}.
    # @!attribute [rw] url
    #   @return [String] Destination URL the audit service sends each event to.
    # @!attribute [rw] headers
    #   @return [Array<HttpHeader>] Headers attached to every outbound request.
    #     Values carry credentials and are encrypted at rest server-side; reads
    #     return them redacted.
    # @!attribute [rw] success_status
    #   @return [String] Status the destination must return for delivery to count
    #     as success — an exact code (+"200"+, +"204"+) or a class (+"2xx"+, +"4xx"+).
    #     Defaults to +"2xx"+.
    #
    # rubocop:disable Lint/StructNewOverride -- ``:method`` matches the
    # API attribute and shadowing Struct#method is the expected ergonomics.
    HttpConfiguration = Struct.new(:method, :url, :headers, :success_status, keyword_init: true) do
      def initialize(method: HttpMethod::POST, url: "", headers: nil, success_status: "2xx")
        super(method: HttpMethod.coerce(method), url: url, headers: headers || [], success_status: success_status)
      end

      def self.to_wire(src)
        h = src.is_a?(Hash) ? new(**src) : src
        SmplkitGeneratedClient::Audit::HttpConfiguration.new(
          method: HttpMethod.coerce(h.method),
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
          method: src.method || HttpMethod::POST,
          url: src.url || "",
          headers: (src.headers || []).map { |h| HttpHeader.new(name: h.name, value: h.value) },
          success_status: src.success_status || "2xx"
        )
      end
    end
    # rubocop:enable Lint/StructNewOverride

    # A SIEM streaming forwarder configured on the customer's account.
    #
    # Active-record style: instantiate via
    # +mgmt.audit.forwarders.new_forwarder(...)+, mutate fields directly,
    # and call {#save} to persist or {#delete} to remove. Header values in
    # +configuration.headers+ are returned redacted on reads — the GET path
    # on the audit API replaces every header value with +"<redacted>"+.
    # Re-supply real values before calling {#save}; the SDK does not cache
    # them client-side.
    class Forwarder
      # @return [String, nil] Server-assigned UUID, +nil+ until {#save} has run.
      attr_accessor :id

      # @return [String] Display name. Free-form.
      attr_accessor :name

      # @return [String] One of {ForwarderType::VALUES}.
      attr_accessor :forwarder_type

      # @return [Boolean] When +false+, the audit service skips delivery for
      #   this forwarder but still records +filtered_out+ deliveries.
      attr_accessor :enabled

      # @return [HttpConfiguration] Destination request configuration.
      attr_accessor :configuration

      # @return [String, nil] Optional free-text description.
      attr_accessor :description

      # @return [Hash, nil] Optional JSON Logic expression evaluated per event.
      #   When set, events that don't match are recorded as +filtered_out+
      #   deliveries instead of being delivered to the destination.
      attr_accessor :filter

      # @return [Object, nil] Optional template applied to each event before
      #   delivery. Free-form — the audit service passes the value verbatim to
      #   the engine named by {#transform_type}. For +TransformType::JSONATA+ a
      #   JSONata expression string; +nil+ delivers the event JSON as-is. Must
      #   be paired with a non-nil {#transform_type}.
      attr_accessor :transform

      # @return [String, nil] Engine that evaluates {#transform} — one of
      #   {TransformType::VALUES}. Required whenever {#transform} is set.
      attr_accessor :transform_type

      # @return [String, nil] ISO-8601 timestamp of first persist. +nil+ for an unsaved instance.
      attr_accessor :created_at

      # @return [String, nil] ISO-8601 timestamp of the most recent mutation.
      attr_accessor :updated_at

      # @return [String, nil] Soft-delete timestamp. +nil+ for live forwarders.
      attr_accessor :deleted_at

      # @return [Integer, nil] Monotonic version counter, bumped on every server-side write.
      attr_accessor :version

      def initialize(client = nil, name:, forwarder_type:, configuration:,
                     id: nil, enabled: true, description: nil,
                     filter: nil, transform: nil, transform_type: nil,
                     created_at: nil, updated_at: nil, deleted_at: nil, version: nil)
        @client = client
        @id = id
        @name = name
        @forwarder_type = ForwarderType.coerce(forwarder_type)
        @configuration = configuration
        @enabled = enabled
        @description = description
        @filter = filter
        @transform = transform
        @transform_type = TransformType.coerce(transform_type)
        @created_at = created_at
        @updated_at = updated_at
        @deleted_at = deleted_at
        @version = version
      end

      # Create or update this forwarder on the server.
      #
      # Upsert behavior is driven by {#created_at}: a forwarder with no
      # +created_at+ is created (POST); otherwise it's full-replace updated
      # (PUT). After the call, every field is refreshed from the server
      # response (including newly-assigned +id+, +created_at+, +updated_at+,
      # +version+).
      #
      # @raise [ArgumentError] when {#transform} and {#transform_type} are not
      #   both nil or both set, or when {#transform_type} is +JSONATA+ and
      #   {#transform} is not a +String+.
      # @return [self]
      def save
        raise "Forwarder was constructed without a client; cannot save" if @client.nil?

        self.class.send(:validate_transform_pair!, @transform, @transform_type)
        updated = @created_at.nil? ? @client._create_forwarder(self) : @client._update_forwarder(self)
        _apply(updated)
        self
      end
      alias save! save

      # Soft-delete this forwarder on the server.
      #
      # @return [nil]
      def delete
        raise "Forwarder was constructed without a client or id; cannot delete" if @client.nil? || @id.nil?

        @client.delete(@id)
      end
      alias delete! delete

      # @api private
      def _apply(other)
        @id = other.id
        @name = other.name
        @forwarder_type = other.forwarder_type
        @configuration = other.configuration
        @enabled = other.enabled
        @description = other.description
        @filter = other.filter
        @transform = other.transform
        @transform_type = other.transform_type
        @created_at = other.created_at
        @updated_at = other.updated_at
        @deleted_at = other.deleted_at
        @version = other.version
      end

      # Validate the +(transform, transform_type)+ pair.
      #
      # Both must be nil or both must be set. When +transform_type+ is
      # +TransformType::JSONATA+, +transform+ must be a +String+ (the
      # JSONata expression). Other engines accept any value.
      #
      # @api private
      def self.validate_transform_pair!(transform, transform_type)
        if transform.nil? != transform_type.nil?
          raise ArgumentError,
                "transform and transform_type must be specified together (both nil or both set)"
        end
        return if transform.nil?
        return unless transform_type == TransformType::JSONATA && !transform.is_a?(String)

        raise ArgumentError,
              "transform must be a String when transform_type is JSONATA " \
              "(got #{transform.class})"
      end

      def self.from_resource(resource, client: nil)
        a = resource.attributes
        new(
          client,
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
  end
end
