# frozen_string_literal: true

module Smplkit
  module Audit
    # Audit events surface — accessed via +client.audit.events+.
    #
    # +#record+ is fire-and-forget — the call enqueues the event onto an
    # in-memory bounded buffer and returns immediately. +#list+ and +#get+
    # are synchronous reads.
    class Events
      def initialize(api)
        @api = api
        @buffer = EventBuffer.new(api)
      end

      # Enqueue an audit event for asynchronous delivery.
      #
      # Returns immediately — the buffer's worker thread performs the actual
      # POST with retry on transient failures.
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
      # @return [void]
      def record(event_type:, resource_type:, resource_id:,
                 occurred_at: nil, actor_type: nil, actor_id: nil,
                 actor_label: nil, category: nil, data: nil, idempotency_key: nil,
                 do_not_forward: false)
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
          data: data || {},
          do_not_forward: do_not_forward
        )
        resource = SmplkitGeneratedClient::Audit::EventResource.new(
          id: "",
          type: "event",
          attributes: attrs
        )
        body = SmplkitGeneratedClient::Audit::EventRequest.new(data: resource)
        @buffer.enqueue(body, idempotency_key)
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
      # @param occurred_at_range [String, nil] Restrict to events whose
      #   +occurred_at+ falls in this range. Omit to leave the time window open.
      # @param search [String, nil] Optional free-text filter — returns only
      #   events whose +resource_id+ or +description+ contains it as a
      #   case-insensitive substring. Must be scoped (combine with
      #   +occurred_at_range+, or with both +resource_type+ and +resource_id+)
      #   or the request is rejected. Omit to disable text filtering.
      # @param environments [Array<String>, nil] Environment keys (and/or the
      #   reserved +"smplkit"+ control-plane bucket) to scope the read to. Omit
      #   to leave the filter off entirely.
      # @param page_size [Integer, nil] Maximum number of events to return in
      #   this page.
      # @param page_after [String, nil] Opaque cursor from a previous page's
      #   +next_cursor+. Omit for the first page.
      # @return [Smplkit::Audit::ListEventsPage] A page of the matching events;
      #   its +#next_cursor+ is set when more pages are available.
      def list(event_type: nil, resource_type: nil, resource_id: nil,
               actor_type: nil, actor_id: nil, occurred_at_range: nil,
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
        opts[:filter_occurred_at] = occurred_at_range if occurred_at_range
        opts[:filter_search] = search if search
        joined_environments = Smplkit::Audit.join_environments(environments)
        opts[:filter_environment] = joined_environments if joined_environments
        opts[:page_size] = page_size if page_size
        opts[:page_after] = page_after if page_after

        resp = Smplkit::Audit.call_api { @api.list_events(opts) }
        events = (resp.data || []).map { |r| AuditEvent.from_resource(r) }
        ListEventsPage.new(events, Smplkit::Audit.next_cursor(resp.links&._next))
      end

      # Block until the in-memory buffer is drained or the timeout elapses.
      #
      # Useful for draining buffered events at process shutdown or after a batch
      # of fire-and-forget records.
      #
      # @param timeout [Float, nil] Upper bound on the blocking flush, in
      #   seconds. +nil+ blocks indefinitely. Defaults to +5.0+.
      # @return [void]
      def flush(timeout: 5.0)
        @buffer.flush(timeout: timeout)
      end

      # @api private — drains best-effort and stops the worker thread.
      def _close
        @buffer.close
      end
    end

    # One page of events plus a cursor for the next page (nil on the last page).
    ListEventsPage = Struct.new(:events, :next_cursor)
  end
end
