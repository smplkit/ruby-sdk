# frozen_string_literal: true

module Smplkit
  module Management
    # Audit management surface — accessed via +mgmt.audit.forwarders+.
    #
    # Counterpart to the runtime {Smplkit::Audit::AuditClient}. The
    # runtime client owns event recording and read-side queries; this
    # surface owns SIEM forwarder CRUD. ADR-047 §2.7.
    class AuditNamespace
      attr_reader :forwarders

      def initialize(api_client)
        @forwarders = ForwardersNamespace.new(
          SmplkitGeneratedClient::Audit::ForwardersApi.new(api_client)
        )
      end
    end

    # +mgmt.audit.forwarders.*+ — manage the customer's configured SIEM
    # forwarders.
    class ForwardersNamespace
      def initialize(api)
        @api = api
      end

      # Create a forwarder.
      #
      # @param name [String] Display name. The slug is derived
      #   server-side.
      # @param forwarder_type [String, Smplkit::Audit::ForwarderType]
      #   One of the published {Smplkit::Audit::ForwarderType} constants
      #   (or the equivalent string).
      # @param http [Smplkit::Audit::ForwarderHttp, Hash] Destination
      #   configuration. Headers carry credentials and are encrypted at
      #   rest server-side; reads return them redacted.
      # @param enabled [Boolean] Whether the forwarder is active.
      # @param filter [Hash, nil] Optional JSON Logic filter; events
      #   that don't match are recorded as +filtered_out+ deliveries.
      # @param transform [String, nil] Optional JSONata template
      #   applied to the event payload before POST. Nil/empty sends the
      #   event as-is.
      def create(name:, forwarder_type:, http:, enabled: true,
                 filter: nil, transform: nil)
        body = build_body(nil, name: name, forwarder_type: forwarder_type,
                               http: http, enabled: enabled,
                               filter: filter, transform: transform)
        resp = Smplkit::Audit.call_api { @api.create_forwarder(body) }
        Smplkit::Audit::Forwarder.from_resource(resp.data)
      end

      def list(forwarder_type: nil, enabled: nil, page_size: nil, page_after: nil)
        opts = {}
        opts[:filter_forwarder_type] = Smplkit::Audit::ForwarderType.coerce(forwarder_type) if forwarder_type
        opts[:filter_enabled] = enabled unless enabled.nil?
        opts[:page_size] = page_size if page_size
        opts[:page_after] = page_after if page_after

        resp = Smplkit::Audit.call_api { @api.list_forwarders(opts) }
        forwarders = (resp.data || []).map { |r| Smplkit::Audit::Forwarder.from_resource(r) }
        ForwarderListPage.new(forwarders, Smplkit::Audit.next_cursor(resp.links&._next))
      end

      def get(forwarder_id)
        resp = Smplkit::Audit.call_api { @api.get_forwarder(forwarder_id) }
        Smplkit::Audit::Forwarder.from_resource(resp.data)
      end

      # Full-replace update. PUT semantics — every field is overwritten.
      #
      # Header values must be re-supplied as plaintext; the GET path
      # redacts them, so a PUT body containing +"<redacted>"+ would
      # persist that literal. Track real header values client-side and
      # round-trip them on update.
      def update(forwarder_id, name:, forwarder_type:, http:, enabled: true,
                 filter: nil, transform: nil)
        body = build_body(forwarder_id, name: name, forwarder_type: forwarder_type,
                                        http: http, enabled: enabled,
                                        filter: filter, transform: transform)
        resp = Smplkit::Audit.call_api { @api.update_forwarder(forwarder_id, body) }
        Smplkit::Audit::Forwarder.from_resource(resp.data)
      end

      def delete(forwarder_id)
        Smplkit::Audit.call_api { @api.delete_forwarder(forwarder_id) }
        nil
      end

      private

      def build_body(id, name:, forwarder_type:, http:, enabled:, filter:, transform:)
        attrs = SmplkitGeneratedClient::Audit::Forwarder.new(
          name: name,
          forwarder_type: Smplkit::Audit::ForwarderType.coerce(forwarder_type),
          enabled: enabled,
          http: Smplkit::Audit::ForwarderHttp.to_wire(http),
          filter: filter,
          transform: transform
        )
        resource = SmplkitGeneratedClient::Audit::ForwarderResource.new(
          id: id ? id.to_s : "",
          type: "forwarder",
          attributes: attrs
        )
        SmplkitGeneratedClient::Audit::ForwarderRequest.new(data: resource)
      end
    end

    ForwarderListPage = Struct.new(:forwarders, :next_cursor)
  end
end
