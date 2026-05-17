# frozen_string_literal: true

module Smplkit
  module Management
    # Audit management surface — accessed via +mgmt.audit.forwarders+.
    #
    # Counterpart to the runtime {Smplkit::Audit::AuditClient}. The
    # runtime client owns event recording and read-side queries; this
    # surface owns SIEM forwarder CRUD. ADR-047 §2.7.
    class AuditNamespace
      # @return [ForwardersNamespace] CRUD surface for +mgmt.audit.forwarders+.
      attr_reader :forwarders

      def initialize(api_client)
        @forwarders = ForwardersNamespace.new(
          SmplkitGeneratedClient::Audit::ForwardersApi.new(api_client)
        )
      end
    end

    # +mgmt.audit.forwarders.*+ — manage the customer's configured SIEM
    # forwarders.
    #
    # The active-record entry point is {#new_forwarder}: instantiate a
    # draft, mutate fields, then call {Smplkit::Audit::Forwarder#save}.
    # The namespace exposes {#list}, {#get}, and {#delete} directly; the
    # +_create_forwarder+ / +_update_forwarder+ helpers are private and
    # invoked by {Smplkit::Audit::Forwarder#save}.
    class ForwardersNamespace
      def initialize(api)
        @api = api
      end

      # Construct an unsaved {Smplkit::Audit::Forwarder} bound to this
      # namespace. Call +#save+ on the returned instance to persist.
      #
      # @param name [String] Display name.
      # @param forwarder_type [String] One of {Smplkit::Audit::ForwarderType::VALUES}.
      # @param configuration [Smplkit::Audit::HttpConfiguration] Destination
      #   request configuration. Headers carry credentials and are encrypted at
      #   rest server-side; reads return them redacted.
      # @param enabled [Boolean] Whether the forwarder is active. Defaults +true+.
      # @param description [String, nil] Optional free-text description.
      # @param filter [Hash, nil] Optional JSON Logic filter; events that don't
      #   match are recorded as +filtered_out+ deliveries.
      # @param transform [String, nil] Optional JSONata template applied to the
      #   event payload before delivery. Nil sends the event JSON unchanged.
      # @return [Smplkit::Audit::Forwarder]
      def new_forwarder(name:, forwarder_type:, configuration:,
                        enabled: true, description: nil,
                        filter: nil, transform: nil)
        Smplkit::Audit::Forwarder.new(
          self,
          name: name,
          forwarder_type: forwarder_type,
          configuration: configuration,
          enabled: enabled,
          description: description,
          filter: filter,
          transform: transform,
          transform_type: transform.nil? ? nil : "JSONATA"
        )
      end

      # List forwarders for the authenticated account.
      #
      # Offset paginated per ADR-014: pass +page_number+ (1-based) and
      # +page_size+ (default 1000, max 1000). Pass +meta_total: true+ to
      # populate +total+ and +total_pages+ in the returned +pagination+
      # block (costs an extra COUNT query server-side).
      #
      # @return [ForwarderListPage]
      def list(forwarder_type: nil, enabled: nil, page_number: nil, page_size: nil, meta_total: nil)
        opts = {}
        opts[:filter_forwarder_type] = Smplkit::Audit::ForwarderType.coerce(forwarder_type) if forwarder_type
        opts[:filter_enabled] = enabled unless enabled.nil?
        opts[:page_number] = page_number if page_number
        opts[:page_size] = page_size if page_size
        opts[:meta_total] = meta_total unless meta_total.nil?

        resp = Smplkit::Audit.call_api { @api.list_forwarders(opts) }
        forwarders = (resp.data || []).map do |r|
          Smplkit::Audit::Forwarder.from_resource(r, client: self)
        end
        ForwarderListPage.new(forwarders, Smplkit::Audit.extract_pagination(resp.meta))
      end

      # Fetch a single forwarder by id. The returned instance is bound to
      # this namespace, so +forwarder.save+ and +forwarder.delete+ work.
      #
      # @param forwarder_id [String]
      # @return [Smplkit::Audit::Forwarder]
      def get(forwarder_id)
        resp = Smplkit::Audit.call_api { @api.get_forwarder(forwarder_id) }
        Smplkit::Audit::Forwarder.from_resource(resp.data, client: self)
      end

      # Soft-delete a forwarder.
      #
      # @param forwarder_id [String]
      # @return [nil]
      def delete(forwarder_id)
        Smplkit::Audit.call_api { @api.delete_forwarder(forwarder_id) }
        nil
      end

      # @api private — POST a new forwarder. Called by
      #   {Smplkit::Audit::Forwarder#save} on unsaved instances.
      def _create_forwarder(forwarder)
        resp = Smplkit::Audit.call_api { @api.create_forwarder(build_body(forwarder)) }
        Smplkit::Audit::Forwarder.from_resource(resp.data, client: self)
      end

      # @api private — Full-replace PUT for an existing forwarder. Called
      #   by {Smplkit::Audit::Forwarder#save} on instances with +created_at+.
      #
      # Header values must be re-supplied as plaintext; the GET path
      # redacts them, so a PUT body containing +"<redacted>"+ would
      # persist that literal. Track real header values client-side and
      # round-trip them.
      def _update_forwarder(forwarder)
        raise ArgumentError, "cannot update a Forwarder with no id" if forwarder.id.nil?

        resp = Smplkit::Audit.call_api { @api.update_forwarder(forwarder.id, build_body(forwarder)) }
        Smplkit::Audit::Forwarder.from_resource(resp.data, client: self)
      end

      private

      def build_body(forwarder)
        attrs = SmplkitGeneratedClient::Audit::Forwarder.new(
          name: forwarder.name,
          description: forwarder.description,
          forwarder_type: Smplkit::Audit::ForwarderType.coerce(forwarder.forwarder_type),
          enabled: forwarder.enabled,
          filter: forwarder.filter,
          transform_type: forwarder.transform_type,
          transform: forwarder.transform,
          configuration: Smplkit::Audit::HttpConfiguration.to_wire(forwarder.configuration)
        )
        resource = SmplkitGeneratedClient::Audit::ForwarderResource.new(
          id: forwarder.id ? forwarder.id.to_s : "",
          type: "forwarder",
          attributes: attrs
        )
        SmplkitGeneratedClient::Audit::ForwarderRequest.new(data: resource)
      end
    end

    # A single page returned from {ForwardersNamespace#list}.
    #
    # @!attribute [rw] forwarders
    #   @return [Array<Smplkit::Audit::Forwarder>] Forwarders in this page.
    # @!attribute [rw] pagination
    #   @return [Hash] +meta.pagination+ block (+:page+, +:size+, and — only when
    #     the caller passed +meta_total: true+ — +:total+ / +:total_pages+).
    ForwarderListPage = Struct.new(:forwarders, :pagination)
  end
end
