# frozen_string_literal: true

module Smplkit
  module Audit
    # Audit events surface — accessed via +client.audit.events+.
    #
    # +#record+ is fire-and-forget per ADR-047 §2.6 — the call enqueues
    # the event onto an in-memory bounded buffer and returns
    # immediately. +#list+ and +#get+ are synchronous reads.
    class Events
      def initialize(api)
        @api = api
        @buffer = EventBuffer.new(api)
      end

      # Enqueue an audit event for asynchronous delivery.
      #
      # Customer attempts to record events with +resource_type+ starting
      # with +smpl.+ are rejected by the server with a 403 (the buffer
      # logs and drops permanent failures).
      def record(action:, resource_type:, resource_id:,
                 occurred_at: nil, data: nil, idempotency_key: nil,
                 do_not_forward: false)
        raise ArgumentError, "action is required" if action.nil? || action.to_s.empty?
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
          action: action,
          resource_type: resource_type,
          resource_id: resource_id,
          occurred_at: normalized_occurred_at,
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
      # Raises {Smplkit::NotFoundError} when no event with that id
      # exists in the caller's account.
      def get(event_id)
        resp = Smplkit::Audit.call_api { @api.get_event(event_id) }
        AuditEvent.from_resource(resp.data)
      end

      # List events with filters and cursor pagination. Returns a
      # +Smplkit::Audit::ListEventsPage+ whose +#events+ is the page and
      # +#next_cursor+ is the opaque token for the next page (or nil).
      def list(action: nil, resource_type: nil, resource_id: nil,
               actor_type: nil, actor_id: nil, occurred_at_range: nil,
               search: nil, page_size: nil, page_after: nil)
        # Generated client opts use snake_case keys that internally map
        # to the JSON:API ``filter[*]`` / ``page[*]`` query-string format
        # (see default_api.rb#list_events_with_http_info). Without the
        # underscores these silently fall through and the filters never
        # reach the server.
        opts = {}
        opts[:filter_action] = action if action
        opts[:filter_resource_type] = resource_type if resource_type
        opts[:filter_resource_id] = resource_id if resource_id
        opts[:filter_actor_type] = actor_type if actor_type
        opts[:filter_actor_id] = actor_id if actor_id
        opts[:filter_occurred_at] = occurred_at_range if occurred_at_range
        opts[:filter_search] = search if search
        opts[:page_size] = page_size if page_size
        opts[:page_after] = page_after if page_after

        resp = Smplkit::Audit.call_api { @api.list_events(opts) }
        events = (resp.data || []).map { |r| AuditEvent.from_resource(r) }
        ListEventsPage.new(events, Smplkit::Audit.next_cursor(resp.links&._next))
      end

      # Block until the in-memory buffer is drained or the timeout elapses.
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
