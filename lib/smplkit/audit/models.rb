# frozen_string_literal: true

module Smplkit
  module Audit
    # Wrap a generated-audit-API call and translate +ApiError+ into the
    # +Smplkit::Error+ hierarchy. Connection-level failures (no
    # response code) become {Smplkit::ConnectionError}; status-coded
    # failures route through {Smplkit::Errors.raise_for_status}, which
    # emits +PaymentRequiredError+ / +NotFoundError+ / +ConflictError+
    # / +ValidationError+ / +Error+ depending on the JSON:API body.
    #
    # @api private
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
    #
    # @api private
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
    #
    # @api private
    def self.extract_pagination(meta)
      pagination = meta&.pagination
      return {} if pagination.nil?

      out = { page: pagination.page, size: pagination.size }
      out[:total] = pagination.total unless pagination.total.nil?
      out[:total_pages] = pagination.total_pages unless pagination.total_pages.nil?
      out
    end

    # Coerce a caller-supplied +environments+ value into the comma-separated
    # string the audit read endpoints expect for +filter[environment]+, or
    # +nil+ when no filter should be sent.
    #
    # The audit read endpoints (events list, the resource_type / event_type /
    # category discovery lists) accept an optional comma-separated
    # +filter[environment]+ of real environment keys and/or the reserved
    # +"smplkit"+ control-plane bucket. The wrapper takes an array of keys for
    # an ergonomic surface and joins it here.
    #
    # +nil+ or an empty array (or one whose entries are all blank) returns
    # +nil+ so the caller omits the query param entirely and behaves exactly
    # as before — existing callers are byte-for-byte unchanged on the wire.
    # +"smplkit"+ is passed through like any other key; it carries no special
    # handling in the SDK.
    #
    # @api private
    def self.join_environments(environments)
      return nil if environments.nil?

      values = Array(environments).map { |e| e.to_s.strip }.reject(&:empty?)
      values.empty? ? nil : values.join(",")
    end

    # Resolve the +filter[environment]+ value for a read surface.
    #
    # An explicit, non-empty +environments+ list always wins and is comma-joined
    # via {join_environments}. Otherwise the client's configured +default+
    # environment scopes the read — the body-driven replacement for the old
    # per-request +X-Smplkit-Environment+ header (ADR-055), which previously
    # scoped every read to the client's environment. A client with no configured
    # environment and no explicit list returns +nil+ so the caller omits the
    # query param and the credential's own scoping applies server-side.
    #
    # @param environments [Array<String>, String, nil] Explicit per-call
    #   environment filter; an empty/blank value falls through to +default+.
    # @param default [String, nil] The client's configured environment.
    # @return [String, nil] The +filter[environment]+ value, or +nil+ to omit it.
    # @api private
    def self.resolve_environment_filter(environments, default)
      joined = join_environments(environments)
      return joined unless joined.nil?

      default
    end

    # Supported SIEM forwarder destination types.
    #
    # Members are declared in alphabetical order. Customers pass these
    # constants — or the equivalent string — to the forwarders surface
    # (+client.audit.forwarders+); the wrapper validates membership via
    # {coerce} before round-tripping to the wire.
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

    # HTTP verb used by a forwarder's outbound delivery.
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

    # Engine that evaluates a forwarder's +transform+ template.
    # Only +JSONATA+ is supported today; the enum exists so the field is
    # typed instead of accepting any string, and so additional engines
    # can be added without breaking the public surface.
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

    # A single audit event as returned by the audit service.
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
    # @!attribute [rw] category
    #   @return [String, nil] Free-form bucket label for the event — e.g.
    #     +"auth"+, +"billing"+, +"config-change"+. Stored exactly as supplied;
    #     drives the audit log's category filter and the +categories+ discovery
    #     listing ({Smplkit::Audit::AuditClient#categories}). +nil+ when not supplied.
    # @!attribute [rw] data
    #   @return [Hash{String => Object}] Free-form per-event payload defined by the customer.
    # @!attribute [rw] idempotency_key
    #   @return [String, nil] Customer-supplied dedupe key, +nil+ if not provided.
    # @!attribute [rw] do_not_forward
    #   @return [Boolean] When +true+, skip SIEM forwarder delivery regardless of any matching filter.
    # @!attribute [rw] environment
    #   @return [String, nil] The environment the event was recorded in.
    #     Read-only and always present on reads — the audit service resolves it
    #     when the event is recorded (from a single-environment credential, or
    #     from the runtime SDK's configured environment, which the SDK sends on
    #     the recording request body).
    AuditEvent = Struct.new(
      :id, :event_type, :resource_type, :resource_id,
      :occurred_at, :created_at,
      :actor_type, :actor_id, :actor_label, :category,
      :data, :idempotency_key, :do_not_forward, :environment,
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
          category: attrs.category,
          data: Smplkit::Helpers.deep_stringify_keys(attrs.data || {}),
          idempotency_key: attrs.idempotency_key,
          do_not_forward: attrs.do_not_forward || false,
          environment: attrs.environment
        )
      end
    end

    # A distinct +resource_type+ slug seen for the account.
    #
    # The +id+ and +resource_type+ are the same value — JSON:API surfaces
    # the customer-facing key as the resource id. The duplication keeps SDK
    # consumers from having to dig into the id field when filtering UI
    # controls; pick whichever name reads better in context.
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

    # A distinct +category+ value seen for the account.
    #
    # Same shape as {ResourceType}/{EventType} — +id+ and +category+ are the
    # same value (JSON:API surfaces the customer-facing key as the resource
    # id). +created_at+ is the earliest sighting of this category for the
    # account.
    #
    # @!attribute [rw] id
    #   @return [String] JSON:API resource id (same as +category+).
    # @!attribute [rw] category
    #   @return [String] The distinct category value.
    # @!attribute [rw] created_at
    #   @return [String] ISO-8601 timestamp of the earliest sighting for this value.
    Category = Struct.new(:id, :category, :created_at, keyword_init: true) do
      def self.from_resource(resource)
        attrs = resource.attributes
        new(
          id: resource.id,
          category: attrs.category || resource.id,
          created_at: attrs.created_at
        )
      end
    end

    # Forwarder destination HTTP request shape — the base configuration.
    #
    # @!attribute [rw] method
    #   @return [String] HTTP verb used for delivery. Defaults to {HttpMethod::POST}.
    # @!attribute [rw] url
    #   @return [String] Destination URL the audit service sends each event to.
    # @!attribute [rw] headers
    #   @return [Hash{String => String}] Headers attached to every outbound
    #     request, as a name→value object (e.g. +{ "DD-API-KEY" => "s3cr3t" }+).
    #     Use {#set_header} / {#get_header} to read and write individual headers.
    #     Values often carry credentials and are returned in plaintext on reads,
    #     so a get-mutate-put round-trip preserves them without re-entering
    #     secrets.
    # @!attribute [rw] success_status
    #   @return [String] Status the destination must return for delivery to count
    #     as success — an exact code (+"200"+, +"204"+) or a class (+"2xx"+, +"4xx"+).
    #     Defaults to +"2xx"+.
    # @!attribute [rw] tls_verify
    #   @return [Boolean] Whether to verify the destination's TLS certificate
    #     chain. Defaults to +true+; flip to +false+ only for short-lived
    #     testing against a destination that serves an untrusted certificate.
    #     Prefer pinning the issuing CA via +ca_cert+ for long-lived self-signed
    #     setups.
    # @!attribute [rw] ca_cert
    #   @return [String, nil] Optional PEM-encoded certificate (or bundle)
    #     trusted in addition to the system CA store. Ignored when
    #     +tls_verify+ is +false+. +nil+ (the default) means "use system CAs
    #     only".
    #
    # rubocop:disable Lint/StructNewOverride -- ``:method`` matches the
    # API attribute and shadowing Struct#method is the expected ergonomics.
    HttpConfiguration = Struct.new(
      :method, :url, :headers, :success_status, :tls_verify, :ca_cert,
      keyword_init: true
    ) do
      def initialize(
        method: HttpMethod::POST, url: "", headers: nil,
        success_status: "2xx", tls_verify: true, ca_cert: nil
      )
        super(
          method: HttpMethod.coerce(method), url: url, headers: (headers || {}).transform_keys(&:to_s),
          success_status: success_status, tls_verify: tls_verify, ca_cert: ca_cert
        )
      end

      # Set (or replace) a single request header by name.
      #
      # @param name [String] Header name.
      # @param value [String] Header value.
      def set_header(name, value)
        self.headers ||= {}
        headers[name.to_s] = value
      end

      # The value of header +name+, or +nil+ when it is not set.
      #
      # @param name [String] Header name.
      # @return [String, nil]
      def get_header(name)
        (headers || {})[name.to_s]
      end

      def self.to_wire(src)
        h = src.is_a?(Hash) ? new(**src) : src
        SmplkitGeneratedClient::Audit::ForwarderHttpConfiguration.new(
          method: HttpMethod.coerce(h.method),
          url: h.url,
          headers: (h.headers || {}).transform_keys(&:to_s),
          success_status: h.success_status,
          tls_verify: h.tls_verify,
          ca_cert: h.ca_cert
        )
      end

      def self.from_wire(src)
        return new if src.nil?

        # Absent ``tls_verify`` on the wire means a forwarder persisted
        # before the field landed — default to verifying so its prior
        # secure behaviour is preserved. Header keys arrive as symbols (the
        # generated client symbolizes JSON) — stringify them so {#get_header}
        # and round-trips behave by name.
        new(
          method: src.method || HttpMethod::POST,
          url: src.url || "",
          headers: (src.headers || {}).transform_keys(&:to_s),
          success_status: src.success_status || "2xx",
          # rubocop:disable Style/RedundantCondition -- nil and false are
          # distinct: nil means "field absent on the wire" (default to true);
          # explicit false means "verification disabled".
          tls_verify: src.tls_verify.nil? ? true : src.tls_verify,
          # rubocop:enable Style/RedundantCondition
          ca_cert: src.ca_cert
        )
      end
    end
    # rubocop:enable Lint/StructNewOverride

    # The per-environment scalar override leaves a forwarder may set (everything
    # except +enabled+ and +headers+, which are addressed individually as
    # +headers.<name>+). Forwarders are event-driven, so — unlike jobs — there is
    # no schedule / timezone / retry_policy leaf. These map 1:1 onto
    # {ForwarderEnvironment} fields and onto the flat overlay's leaf paths.
    #
    # @api private
    FORWARDER_ENV_SCALAR_LEAVES = %i[url method success_status tls_verify ca_cert].freeze
    # The same leaves as wire-key strings, for parsing the flat overlay.
    #
    # @api private
    FORWARDER_ENV_SCALAR_LEAF_NAMES = FORWARDER_ENV_SCALAR_LEAVES.map(&:to_s).freeze

    # One environment's *sparse override* for a forwarder (ADR-056).
    #
    # A forwarder's {Forwarder#environments} map holds one of these per
    # environment. Only the leaves you set are sent on save; everything you leave
    # unset is inherited from the forwarder's base definition, and the server
    # resolves base ⊕ overrides when an event is delivered. The base definition
    # delivers nowhere, so a forwarder delivers in an environment only when that
    # environment's override sets +enabled: true+.
    #
    # Reach one through {Forwarder#environment}, e.g.
    # +forwarder.environment("production").url = "https://prod.siem.example.com/in"+.
    #
    # *Reading a leaf returns this environment's override, or +nil+ when it does
    # not override that leaf* — the SDK does not merge in the base value
    # (forwarders resolve server-side). To see a base value, read the forwarder's
    # base definition ({Forwarder#configuration}).
    #
    # @!attribute [rw] enabled
    #   @return [Boolean] Whether the forwarder delivers events in this
    #     environment. Defaults to +false+.
    # @!attribute [rw] url
    #   @return [String, nil] Per-environment URL override. +nil+ inherits the base.
    # @!attribute [rw] method
    #   @return [String, nil] Per-environment HTTP-method override. +nil+ inherits the base.
    # @!attribute [rw] success_status
    #   @return [String, nil] Per-environment success-status override. +nil+ inherits the base.
    # @!attribute [rw] tls_verify
    #   @return [Boolean, nil] Per-environment TLS-verify override. +nil+ inherits the base.
    # @!attribute [rw] ca_cert
    #   @return [String, nil] Per-environment CA-cert override. +nil+ inherits the base.
    # @!attribute [rw] headers
    #   @return [Hash{String => String}] Per-environment header overrides, as a
    #     name→value object. Each entry overrides (or adds) that one header by name
    #     on top of the base headers, leaving the rest inherited. Use {#set_header}
    #     / {#get_header}.
    #
    # rubocop:disable Lint/StructNewOverride -- ``:method`` matches the
    # API attribute and shadowing Struct#method is the expected ergonomics.
    ForwarderEnvironment = Struct.new(
      :enabled, :url, :method, :success_status, :tls_verify, :ca_cert, :headers,
      keyword_init: true
    ) do
      def initialize(enabled: false, url: nil, method: nil, success_status: nil,
                     tls_verify: nil, ca_cert: nil, headers: nil)
        super(
          enabled: enabled, url: url, method: method, success_status: success_status,
          tls_verify: tls_verify, ca_cert: ca_cert, headers: (headers || {}).transform_keys(&:to_s)
        )
      end

      # Override (or add) a single header by name in this environment.
      #
      # @param name [String] Header name.
      # @param value [String] Header value.
      def set_header(name, value)
        self.headers ||= {}
        headers[name.to_s] = value
      end

      # This environment's override for header +name+, or +nil+ when it does not
      # override that header.
      #
      # @param name [String] Header name.
      # @return [String, nil]
      def get_header(name)
        (headers || {})[name.to_s]
      end

      # @api private — Emit the flat sparse leaf-path overlay (ADR-056): +enabled+
      #   plus only the leaves this environment overrides, with each header as a
      #   +headers.<name>+ leaf.
      #
      # @return [Hash{String => Object}]
      def to_payload
        payload = { "enabled" => enabled }
        FORWARDER_ENV_SCALAR_LEAVES.each do |leaf|
          value = self[leaf]
          payload[leaf.to_s] = value unless value.nil?
        end
        (headers || {}).each { |name, value| payload["headers.#{name}"] = value }
        payload
      end

      # @api private — Parse the flat leaf-path overlay the server returns
      #   (ADR-056). Header leaves arrive as +headers.<name>+ (split on the first
      #   dot, so a dotted header name like +X-Foo.Bar+ is preserved); every other
      #   leaf is a single top-level key. Unknown leaves are ignored for forward
      #   compatibility. Keys may be symbols or strings.
      #
      # @param raw [Hash, nil] The flat overlay hash, or +nil+ for an empty override.
      # @return [ForwarderEnvironment]
      def self.from_flat(raw)
        return new if raw.nil?

        headers = {}
        scalars = {}
        (raw || {}).each do |key, value|
          key = key.to_s
          group, _dot, name = key.partition(".")
          if group == "headers" && !name.empty?
            headers[name] = value
          elsif FORWARDER_ENV_SCALAR_LEAF_NAMES.include?(key) || key == "enabled"
            scalars[key] = value
          end
        end
        new(
          enabled: scalars["enabled"] ? true : false,
          url: scalars["url"], method: scalars["method"],
          success_status: scalars["success_status"], tls_verify: scalars["tls_verify"],
          ca_cert: scalars["ca_cert"], headers: headers
        )
      end
    end
    # rubocop:enable Lint/StructNewOverride

    # A SIEM streaming forwarder configured on the customer's account.
    #
    # Active-record style: instantiate via
    # +client.audit.forwarders.new(...)+, mutate fields directly,
    # and call {#save} to persist or {#delete} to remove. Header values in
    # +configuration.headers+ are returned in plaintext on reads, so fetching
    # a forwarder, mutating it, and calling {#save} preserves its header
    # values without re-entering secrets.
    class Forwarder
      # @return [String, nil] Caller-supplied unique identifier (key) for this
      #   forwarder. Unique within an account; immutable for the lifetime of
      #   the forwarder. +nil+ only while the object represents an unsaved
      #   instance constructed without an id (which {#save} would then reject).
      attr_accessor :id

      # @return [String] Display name. Free-form.
      attr_accessor :name

      # @return [String] One of {ForwarderType::VALUES}.
      attr_accessor :forwarder_type

      # @return [Boolean] Read-only roll-up: +true+ when the forwarder is enabled
      #   in at least one environment. Derived from {#environments} — there is no
      #   server-side top-level +enabled+ field. Enable per environment via
      #   +forwarder.environment(env).enabled = true+.
      def enabled
        (@environments || {}).each_value.any?(&:enabled)
      end

      # @return [Boolean] When +true+, this forwarder also receives platform
      #   change events that smplkit records about your own resources (flag,
      #   configuration, and similar changes). Each such event is delivered
      #   through every environment this forwarder is enabled in, using that
      #   environment's resolved configuration. Defaults to +false+ — platform
      #   change events are not forwarded unless you opt in. Independent of the
      #   per-environment +enabled+ settings, since platform change events are
      #   not tied to a deployment environment.
      attr_accessor :forward_smplkit_events

      # @return [Hash{String => ForwarderEnvironment}] Per-environment sparse
      #   overrides keyed by environment key (e.g. +"production"+, +"staging"+). A
      #   forwarder delivers in an environment only when
      #   +environments[env].enabled+ is +true+. Each entry overrides only the
      #   leaves it sets; omitted leaves inherit the base {#configuration}. Reach
      #   one via {#environment}. Every referenced environment must exist and be
      #   managed for the account.
      attr_accessor :environments

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

      # @return [String, nil] Deletion timestamp; +nil+ for live forwarders.
      attr_accessor :deleted_at

      # @return [Integer, nil] Monotonic version counter, bumped on every server-side write.
      attr_accessor :version

      def initialize(client = nil, name:, forwarder_type:, configuration:,
                     id: nil, forward_smplkit_events: false,
                     environments: nil, description: nil,
                     filter: nil, transform: nil, transform_type: nil,
                     created_at: nil, updated_at: nil, deleted_at: nil, version: nil)
        @client = client
        @id = id
        @name = name
        @forwarder_type = ForwarderType.coerce(forwarder_type)
        @configuration = configuration
        @forward_smplkit_events = forward_smplkit_events
        @environments = environments || {}
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

      # Delete this forwarder on the server.
      #
      # @return [nil]
      def delete
        raise "Forwarder was constructed without a client or id; cannot delete" if @client.nil? || @id.nil?

        @client.delete(@id)
      end
      alias delete! delete

      # The per-environment override for +environment+ — the single place to read
      # or set what this forwarder overrides there (ADR-056).
      #
      # Returns the {ForwarderEnvironment} for +environment+, creating an empty
      # one (and inserting it into {#environments}) on first access, so you can
      # set overrides directly:
      #
      #   forwarder.environment("production").enabled = true
      #   forwarder.environment("production").url = "https://prod.siem.example.com/in"
      #   forwarder.environment("production").set_header("DD-API-KEY", "prod-secret")
      #
      # Only the leaves you set are sent on save; everything else inherits the
      # base definition (the server resolves base ⊕ overrides on delivery).
      #
      # @param environment [String] The environment key.
      # @return [ForwarderEnvironment]
      def environment(environment)
        @environments[environment] ||= ForwarderEnvironment.new
      end

      # @api private
      def _apply(other)
        @id = other.id
        @name = other.name
        @forwarder_type = other.forwarder_type
        @configuration = other.configuration
        @forward_smplkit_events = other.forward_smplkit_events
        @environments = other.environments
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
        environments = (a.environments || {}).each_with_object({}) do |(env_key, env_raw), out|
          out[env_key.to_s] = ForwarderEnvironment.from_flat(env_raw)
        end
        new(
          client,
          id: resource.id,
          name: a.name,
          description: a.description,
          forwarder_type: a.forwarder_type,
          # The base ``enabled`` roll-up is derived from ``environments``, not
          # read from the wire — the API has no top-level ``enabled``.
          # ``forward_smplkit_events`` defaults to false; a forwarder persisted
          # before the field landed reads back as not opted in.
          forward_smplkit_events: a.forward_smplkit_events.nil? ? false : a.forward_smplkit_events,
          environments: environments,
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
