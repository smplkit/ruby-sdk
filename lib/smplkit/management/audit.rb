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
      # @param name [String] Display name.
      # @param forwarder_type [String, Smplkit::Audit::ForwarderType]
      #   One of the published {Smplkit::Audit::ForwarderType} constants
      #   (or the equivalent string).
      # @param configuration [Smplkit::Audit::HttpConfiguration, Hash]
      #   Transport-specific delivery configuration. Today every
      #   forwarder_type uses {HttpConfiguration}; the URL and header
      #   values inside are stored encrypted server-side and round-trip
      #   to GET in plaintext.
      # @param description [String, nil] Optional free-text description.
      # @param enabled [Boolean] Whether the forwarder is active.
      # @param filter [Hash, nil] Optional JSON Logic filter; events
      #   that don't match are recorded as +filtered_out+ deliveries.
      # @param transform_type [String, nil] Engine that evaluates
      #   +transform+. Set to +"JSONATA"+ whenever +transform+ is set.
      # @param transform [String, nil] Optional template applied to the
      #   event payload before delivery (for +JSONATA+, a JSONata
      #   expression). Nil sends the event JSON unchanged.
      def create(name:, forwarder_type:, configuration:, description: nil, enabled: true,
                 filter: nil, transform_type: nil, transform: nil)
        body = build_body(nil, name: name, forwarder_type: forwarder_type,
                               configuration: configuration, description: description,
                               enabled: enabled, filter: filter,
                               transform_type: transform_type, transform: transform)
        resp = Smplkit::Audit.call_api { @api.create_forwarder(body) }
        Smplkit::Audit::Forwarder.from_resource(resp.data)
      end

      def list(forwarder_type: nil, enabled: nil, page_number: nil, page_size: nil, meta_total: nil)
        opts = {}
        opts[:filter_forwarder_type] = Smplkit::Audit::ForwarderType.coerce(forwarder_type) if forwarder_type
        opts[:filter_enabled] = enabled unless enabled.nil?
        opts[:page_number] = page_number if page_number
        opts[:page_size] = page_size if page_size
        opts[:meta_total] = meta_total unless meta_total.nil?

        resp = Smplkit::Audit.call_api { @api.list_forwarders(opts) }
        forwarders = (resp.data || []).map { |r| Smplkit::Audit::Forwarder.from_resource(r) }
        ForwarderListPage.new(forwarders, Smplkit::Audit.extract_pagination(resp.meta))
      end

      def get(forwarder_id)
        resp = Smplkit::Audit.call_api { @api.get_forwarder(forwarder_id) }
        Smplkit::Audit::Forwarder.from_resource(resp.data)
      end

      # Full-replace update. PUT semantics — every field is overwritten.
      #
      # The URL and header values inside +configuration+ are returned in
      # plaintext on GET, so a fetched forwarder can be round-tripped to
      # PUT without re-entering secrets.
      def update(forwarder_id, name:, forwarder_type:, configuration:, description: nil,
                 enabled: true, filter: nil, transform_type: nil, transform: nil)
        body = build_body(forwarder_id, name: name, forwarder_type: forwarder_type,
                                        configuration: configuration, description: description,
                                        enabled: enabled, filter: filter,
                                        transform_type: transform_type, transform: transform)
        resp = Smplkit::Audit.call_api { @api.update_forwarder(forwarder_id, body) }
        Smplkit::Audit::Forwarder.from_resource(resp.data)
      end

      def delete(forwarder_id)
        Smplkit::Audit.call_api { @api.delete_forwarder(forwarder_id) }
        nil
      end

      private

      def build_body(id, name:, forwarder_type:, configuration:, description:, enabled:,
                     filter:, transform_type:, transform:)
        attrs = SmplkitGeneratedClient::Audit::Forwarder.new(
          name: name,
          description: description,
          forwarder_type: Smplkit::Audit::ForwarderType.coerce(forwarder_type),
          enabled: enabled,
          filter: filter,
          transform_type: transform_type,
          transform: transform,
          configuration: Smplkit::Audit::HttpConfiguration.to_wire(configuration)
        )
        resource = SmplkitGeneratedClient::Audit::ForwarderResource.new(
          id: id ? id.to_s : "",
          type: "forwarder",
          attributes: attrs
        )
        SmplkitGeneratedClient::Audit::ForwarderRequest.new(data: resource)
      end
    end

    ForwarderListPage = Struct.new(:forwarders, :pagination)
  end
end
