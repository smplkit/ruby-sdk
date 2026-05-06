# frozen_string_literal: true

module Smplkit
  module Audit
    # Audit events surface — accessed via +client.audit.events+.
    #
    # +#create+ is fire-and-forget per ADR-047 §2.6 — the call enqueues
    # the event onto an in-memory bounded buffer and returns
    # immediately. +#list+ and +#get+ are synchronous.
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
      def create(action:, resource_type:, resource_id:,
                 occurred_at: nil, snapshot: nil, data: nil, idempotency_key: nil)
        raise ArgumentError, "action is required" if action.nil? || action.to_s.empty?
        raise ArgumentError, "resource_type is required" if resource_type.nil? || resource_type.to_s.empty?
        raise ArgumentError, "resource_id is required" if resource_id.nil? || resource_id.to_s.empty?

        attrs = SmplkitGeneratedClient::Audit::Event.new(
          action: action,
          resource_type: resource_type,
          resource_id: resource_id,
          occurred_at: occurred_at,
          snapshot: snapshot,
          data: data
        )
        resource = SmplkitGeneratedClient::Audit::EventResource.new(
          id: "",
          type: "event",
          attributes: attrs
        )
        body = SmplkitGeneratedClient::Audit::EventResponse.new(data: resource)
        @buffer.enqueue(body, idempotency_key)
      end

      # Single-event retrieval.
      #
      # Raises +SmplkitGeneratedClient::Audit::ApiError+ on non-2xx
      # responses (404 if the event is not in the caller's account).
      def get(event_id)
        resp = @api.get_event(event_id)
        AuditEvent.from_resource(resp.data)
      end

      # List events with filters and cursor pagination. Returns a
      # +Smplkit::Audit::ListEventsPage+ whose +#events+ is the page and
      # +#next_cursor+ is the opaque token for the next page (or nil).
      def list(action: nil, resource_type: nil, resource_id: nil,
               actor_type: nil, actor_id: nil, occurred_at_range: nil,
               page_size: nil, page_after: nil)
        opts = {}
        opts[:filteraction] = action if action
        opts[:filterresource_type] = resource_type if resource_type
        opts[:filterresource_id] = resource_id if resource_id
        opts[:filteractor_type] = actor_type if actor_type
        opts[:filteractor_id] = actor_id if actor_id
        opts[:filteroccurred_at] = occurred_at_range if occurred_at_range
        opts[:pagesize] = page_size if page_size
        opts[:pageafter] = page_after if page_after

        resp = @api.list_events(opts)
        events = (resp.data || []).map { |r| AuditEvent.from_resource(r) }
        next_cursor = nil
        if resp.links&._next.is_a?(String)
          next_link = resp.links._next
          if (idx = next_link.index("page[after]="))
            next_cursor = next_link[(idx + "page[after]=".length)..]
            if (amp = next_cursor.index("&"))
              next_cursor = next_cursor[0...amp]
            end
          end
        end
        ListEventsPage.new(events, next_cursor)
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

    # Public-facing audit event resource. ADR-047 §2.3.1.
    AuditEvent = Struct.new(
      :id, :action, :resource_type, :resource_id,
      :occurred_at, :created_at,
      :actor_type, :actor_id, :actor_label,
      :snapshot, :data, :idempotency_key,
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
          snapshot: attrs.snapshot,
          data: attrs.data || {},
          idempotency_key: attrs.idempotency_key
        )
      end
    end

    # One page of events plus a cursor for the next page (nil on the last page).
    ListEventsPage = Struct.new(:events, :next_cursor)
  end
end
