# frozen_string_literal: true

module Smplkit
  module Audit
    # Audit events surface — accessed via +client.audit.events+.
    #
    # +#record+ is fire-and-forget by default — the call enqueues the event
    # onto an in-memory bounded buffer and returns immediately. Pass
    # +flush: true+ to block until the event is durable before continuing.
    # In stateless mode (+buffered: false+ on the client) there is no buffer:
    # every +#record+ performs one blocking POST and raises on failure.
    # +#list+ and +#get+ are synchronous reads.
    class Events
      def initialize(api, environment: nil, buffered: true)
        @api = api
        @environment = environment
        # Stateless mode installs no buffer at all — no worker thread, no
        # background state — so a client may be constructed per request in
        # serverless or edge runtimes.
        @buffer = buffered ? EventBuffer.new(api) : nil
      end

      # Record an audit event.
      #
      # In the default buffered mode this enqueues for asynchronous delivery
      # and returns immediately — the buffer's worker thread performs the
      # actual POST with retry on transient failures. When +flush: true+,
      # the call blocks until the buffer has drained or +flush_timeout+
      # elapses; use it when the caller needs the event durable before
      # continuing (CLI tools, in-test assertions, or any flow about to
      # terminate the process).
      #
      # In stateless mode (+buffered: false+ on the client) every call
      # performs one blocking POST and raises one of the SDK's typed errors
      # on failure; +flush+/+flush_timeout+ are meaningless there and
      # ignored.
      #
      # Actor attribution (+actor_type+, +actor_id+, +actor_label+) is
      # customer-supplied and free-form. The audit service stores
      # whatever the caller passed and never backfills from the request
      # credential — supply the fields explicitly when you want the
      # event attributed.
      #
      # @param event_type [String] What happened (e.g. +"invoice.created"+).
      #   Any non-empty string.
      # @param resource_type [String] Kind of resource the event is about (e.g.
      #   +"invoice"+). Any non-empty string. Customer events must NOT use the
      #   +smpl.+ prefix — that namespace is reserved for smplkit-emitted events
      #   and the server rejects customer attempts with a 403 (the buffer logs
      #   and drops permanent failures).
      # @param resource_id [String] Identifier of the affected resource.
      # @param occurred_at [Time, DateTime, String, nil] When the event happened
      #   in the originating system. Defaults to +now+ server-side if omitted.
      # @param actor_type [String, nil] Free-form label for the kind of actor
      #   that caused the event (e.g. +"USER"+, +"API_KEY"+, +"SYSTEM"+, or any
      #   custom value). The audit service never backfills this from the request
      #   credential — supply it explicitly when you want the event attributed.
      # @param actor_id [String, nil] Free-form identifier of the actor that
      #   caused the event. Any string scheme is accepted.
      # @param actor_label [String, nil] Human-readable label for the actor
      #   (e.g. an email address or API key name).
      # @param category [String, nil] Optional free-form bucket label for the
      #   event (e.g. +"auth"+, +"billing"+, +"config-change"+). Stored exactly
      #   as supplied; powers the audit log's category filter and the
      #   +categories+ discovery listing ({Smplkit::Audit::AuditClient#categories}).
      #   Omit it to leave the event uncategorized.
      # @param severity [String, nil] Optional severity level for the event —
      #   one of +"TRACE"+, +"DEBUG"+, +"INFO"+, +"WARN"+, +"ERROR"+, or
      #   +"FATAL"+. Omit it to let the server default the level to +"INFO"+.
      # @param data [Hash, nil] Free-form contextual JSON. To record a resource
      #   snapshot, place it inside +data+ — smplkit's own convention nests it at
      #   +data["snapshot"]+ for consistency, but the shape is unconstrained.
      # @param idempotency_key [String, nil] Optional caller-supplied idempotency
      #   key. If omitted, the server derives one from event content (account_id
      #   + event_type + resource_type + resource_id + occurred_at + actor_* +
      #   data).
      # @param do_not_forward [Boolean] When +true+, the audit service records
      #   the event normally but does NOT POST it through any configured SIEM
      #   forwarder. A +skipped_do_not_forward+ delivery row is recorded for each
      #   enabled forwarder so the skip is visible in the forwarder delivery log.
      # @param flush [Boolean] When +true+, block until the buffer has drained
      #   (or +flush_timeout+ elapses) before returning. Defaults to +false+
      #   (fire-and-forget). Ignored in stateless mode (+buffered: false+),
      #   where every record is already durable on return.
      # @param flush_timeout [Float, nil] Upper bound on the blocking flush, in
      #   seconds. Ignored when +flush+ is +false+ and in stateless mode.
      #   +nil+ blocks indefinitely. Defaults to +5.0+.
      # @return [void]
      def record(event_type:, resource_type:, resource_id:,
                 occurred_at: nil, actor_type: nil, actor_id: nil,
                 actor_label: nil, category: nil, severity: nil, data: nil,
                 idempotency_key: nil, do_not_forward: false, flush: false,
                 flush_timeout: 5.0)
        raise ArgumentError, "event_type is required" if event_type.nil? || event_type.to_s.empty?
        raise ArgumentError, "resource_type is required" if resource_type.nil? || resource_type.to_s.empty?
        raise ArgumentError, "resource_id is required" if resource_id.nil? || resource_id.to_s.empty?

        # Pydantic validation on the server expects an ISO-8601 string
        # for ``occurred_at`` — Ruby's ``Time#to_s`` (which is what the
        # generated client falls back to during JSON serialization)
        # emits ``"2026-05-07 04:43:23 UTC"`` and trips the gate. Coerce
        # Time/DateTime to ``.iso8601`` here so end users can pass the
        # native Ruby type.
        normalized_occurred_at = if occurred_at.respond_to?(:iso8601)
                                   occurred_at.iso8601
                                 else
                                   occurred_at
                                 end

        # Server-side validation also rejects ``data: null`` (the field
        # is required-non-null in the OpenAPI schema). Always default to
        # an empty hash so users who omit ``data:`` don't trip the gate.
        attrs = SmplkitGeneratedClient::Audit::Event.new(
          event_type: event_type,
          resource_type: resource_type,
          resource_id: resource_id,
          occurred_at: normalized_occurred_at,
          actor_type: actor_type,
          actor_id: actor_id,
          actor_label: actor_label,
          category: category,
          severity: severity,
          data: data || {},
          do_not_forward: do_not_forward
        )
        # Stamp the client's configured environment onto the event body — the
        # body-driven replacement for the old +X-Smplkit-Environment+ header
        # (ADR-055). Left off when nil so a single-environment credential
        # resolves it server-side. Assigning conditionally (rather than passing
        # +environment: nil+ through the constructor) keeps the field out of the
        # serialized body entirely when unconfigured.
        attrs.environment = @environment unless @environment.nil?
        resource = SmplkitGeneratedClient::Audit::EventResource.new(
          id: "",
          type: "event",
          attributes: attrs
        )
        body = SmplkitGeneratedClient::Audit::EventRequest.new(data: resource)
        if @buffer.nil?
          # Stateless path: one blocking POST per call — the same wire call
          # the buffer's worker performs, but failures surface to the caller
          # as the SDK's typed errors instead of being retried in background.
          opts = idempotency_key ? { idempotency_key: idempotency_key } : {}
          Smplkit::Audit.call_api { @api.record_event(body, opts) }
          return nil
        end
        @buffer.enqueue(body, idempotency_key)
        @buffer.flush(timeout: flush_timeout) if flush
        nil
      end

      # Single-event retrieval.
      #
      # @param event_id [String] The event's UUID, as a string parseable as one.
      # @return [Smplkit::Audit::AuditEvent] The matching event.
      # @raise [Smplkit::NotFoundError] If no event with that id exists in the
      #   caller's account.
      def get(event_id)
        resp = Smplkit::Audit.call_api { @api.get_event(event_id) }
        AuditEvent.from_resource(resp.data)
      end

      # List audit events for the authenticated account.
      #
      # Filters apply server-side. +actor_id+ is matched as a literal string
      # against whatever the recording call stored. Pagination uses an opaque
      # cursor (+page_after+); the returned page exposes +#next_cursor+ when
      # more pages are available.
      #
      # +search+ is an optional free-text filter: pass a string to return only
      # events whose +resource_id+ or +description+ contains it as a
      # case-insensitive substring; omit it (the default) to disable text
      # filtering. A +search+ filter must be scoped — combine it with
      # +occurred_at_range+, or with both +resource_type+ and +resource_id+ —
      # or the request is rejected.
      #
      # +environments+ scopes the read to a set of environments: pass an array
      # of environment keys and/or the reserved +"smplkit"+ control-plane
      # bucket; the values are sent comma-separated as +filter[environment]+.
      # Omit it (the default) to scope the read to the client's configured
      # environment; with no configured environment the filter is left off
      # entirely.
      #
      # @param event_type [String, nil] Return only events with this
      #   +event_type+. Omit to match any.
      # @param resource_type [String, nil] Return only events about this
      #   +resource_type+. Omit to match any.
      # @param resource_id [String, nil] Return only events about this resource
      #   id. Omit to match any.
      # @param actor_type [String, nil] Return only events whose +actor_type+
      #   equals this value. Omit to match any.
      # @param actor_id [String, nil] Return only events whose +actor_id+
      #   matches this value as a literal string. Omit to match any.
      # @param category [String, nil] Filter to this exact category — the
      #   indexed correlation label callers stamp on related events. Omit to
      #   match any.
      # @param occurred_at_range [String, nil] Restrict to events whose
      #   +occurred_at+ falls in this range. Omit to leave the time window open.
      # @param search [String, nil] Optional free-text filter — returns only
      #   events whose +resource_id+ or +description+ contains it as a
      #   case-insensitive substring. Must be scoped (combine with
      #   +occurred_at_range+, or with both +resource_type+ and +resource_id+)
      #   or the request is rejected. Omit to disable text filtering.
      # @param environments [Array<String>, nil] Environment keys (and/or the
      #   reserved +"smplkit"+ control-plane bucket) to scope the read to. Omit
      #   to fall back to the client's configured environment; with no configured
      #   environment the filter is left off entirely.
      # @param page_size [Integer, nil] Maximum number of events to return in
      #   this page.
      # @param page_after [String, nil] Opaque cursor from a previous page's
      #   +next_cursor+. Omit for the first page.
      # @return [Smplkit::Audit::ListEventsPage] A page of the matching events;
      #   its +#next_cursor+ is set when more pages are available.
      def list(event_type: nil, resource_type: nil, resource_id: nil,
               actor_type: nil, actor_id: nil, category: nil, occurred_at_range: nil,
               search: nil, environments: nil, page_size: nil, page_after: nil)
        # Generated client opts use snake_case keys that internally map
        # to the JSON:API ``filter[*]`` / ``page[*]`` query-string format
        # (see default_api.rb#list_events_with_http_info). Without the
        # underscores these silently fall through and the filters never
        # reach the server.
        opts = {}
        opts[:filter_event_type] = event_type if event_type
        opts[:filter_resource_type] = resource_type if resource_type
        opts[:filter_resource_id] = resource_id if resource_id
        opts[:filter_actor_type] = actor_type if actor_type
        opts[:filter_actor_id] = actor_id if actor_id
        opts[:filter_category] = category if category
        opts[:filter_occurred_at] = occurred_at_range if occurred_at_range
        opts[:filter_search] = search if search
        resolved_environment = Smplkit::Audit.resolve_environment_filter(environments, @environment)
        opts[:filter_environment] = resolved_environment if resolved_environment
        opts[:page_size] = page_size if page_size
        opts[:page_after] = page_after if page_after

        resp = Smplkit::Audit.call_api { @api.list_events(opts) }
        events = (resp.data || []).map { |r| AuditEvent.from_resource(r) }
        ListEventsPage.new(events, Smplkit::Audit.next_cursor(resp.links&._next))
      end

      # Block until the in-memory buffer is drained or the timeout elapses.
      #
      # Useful for draining buffered events at process shutdown or after a batch
      # of fire-and-forget records. A no-op in stateless mode
      # (+buffered: false+), where every record is already durable on return.
      #
      # @param timeout [Float, nil] Upper bound on the blocking flush, in
      #   seconds. +nil+ blocks indefinitely. Defaults to +5.0+.
      # @return [void]
      def flush(timeout: 5.0)
        @buffer&.flush(timeout: timeout)
        nil
      end

      # @api private — drains best-effort and stops the worker thread. A no-op
      #   in stateless mode (+buffered: false+), which has no worker to stop.
      def _close
        @buffer&.close
        nil
      end
    end

    # One page of events plus a cursor for the next page (nil on the last page).
    ListEventsPage = Struct.new(:events, :next_cursor)
  end
end
