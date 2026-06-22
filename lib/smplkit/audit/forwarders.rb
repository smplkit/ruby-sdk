# frozen_string_literal: true

# SIEM forwarder CRUD for the Smpl Audit client.
#
# Forwarders are part of the single unified audit surface — there is no
# runtime/management split for audit (see +Smplkit::Audit::AuditClient+). This
# file holds the forwarder CRUD sub-client that the unified +AuditClient+
# exposes as +.forwarders+:
#
# * +ForwardersClient+ — +forwarders.new/get/list/save/delete+
#
# The forwarder model classes (+Forwarder+, +ForwarderEnvironment+, …) live in
# +lib/smplkit/audit/models.rb+.
module Smplkit
  module Audit
    # Surface for +client.audit.forwarders.*+ — manage the customer's
    # configured SIEM forwarders.
    #
    # The active-record entry point is {#new}: instantiate a draft, mutate
    # fields, then call {Smplkit::Audit::Forwarder#save}. The client exposes
    # {#list}, {#get}, and {#delete} directly; the +_create_forwarder+ /
    # +_update_forwarder+ helpers are invoked by {Smplkit::Audit::Forwarder#save}.
    class ForwardersClient
      def initialize(api)
        @api = api
      end

      # Construct an unsaved {Smplkit::Audit::Forwarder} bound to this client.
      # Call +#save+ on the returned instance to persist.
      #
      # @param id [String] Caller-supplied unique identifier (the forwarder's
      #   key). Unique within the account; immutable. The audit service returns
      #   409 if another live forwarder already uses this id.
      # @param name [String] Display name. Defaults to +id+ when not supplied.
      # @param forwarder_type [String] One of {Smplkit::Audit::ForwarderType::VALUES}.
      # @param configuration [Smplkit::Audit::HttpConfiguration] Destination
      #   request configuration. Header values often carry credentials and are
      #   returned in plaintext on reads, so a get-mutate-put round-trip
      #   preserves them without re-entering secrets.
      # @param environments [Hash{String => Smplkit::Audit::ForwarderEnvironment, Hash}, nil]
      #   Per-environment overrides keyed by environment key (e.g.
      #   +"production"+). A forwarder delivers in an environment only when that
      #   environment's entry has +enabled: true+. Values may be
      #   {Smplkit::Audit::ForwarderEnvironment} instances or plain hashes
      #   (+{ enabled: true }+, optionally with a +:configuration+
      #   {Smplkit::Audit::HttpConfiguration} override). Omit to create a
      #   forwarder that delivers nowhere until enabled per environment.
      # @param description [String, nil] Optional free-text description.
      # @param forward_smplkit_events [Boolean] When +true+, the forwarder also
      #   receives platform change events that smplkit records about the
      #   account's own resources (flag, configuration, and similar changes),
      #   delivered through every environment the forwarder is enabled in.
      #   Defaults to +false+ — omit to leave platform change events unforwarded.
      # @param filter [Hash, nil] Optional JSON Logic filter; events that don't
      #   match are recorded as +filtered_out+ deliveries.
      # @param transform [Object, nil] Optional template applied to each event
      #   before delivery. Must be paired with a non-nil +transform_type+; when
      #   +transform_type+ is +TransformType::JSONATA+, +transform+ must be a
      #   +String+ (the JSONata expression).
      # @param transform_type [String, nil] Engine that evaluates +transform+ —
      #   one of {Smplkit::Audit::TransformType::VALUES}. Must be paired with a
      #   non-nil +transform+.
      # @raise [ArgumentError] when +transform+ and +transform_type+ are not both
      #   nil or both set, or when +transform_type+ is +JSONATA+ and +transform+
      #   is not a +String+.
      # @return [Smplkit::Audit::Forwarder]
      def new(id, forwarder_type:, configuration:, name: nil,
              environments: nil, description: nil,
              forward_smplkit_events: false,
              filter: nil, transform: nil, transform_type: nil)
        Forwarder.send(:validate_transform_pair!, transform, transform_type)
        Forwarder.new(
          self,
          id: id,
          name: name || id,
          forwarder_type: forwarder_type,
          configuration: configuration,
          environments: normalize_environments(environments),
          description: description,
          forward_smplkit_events: forward_smplkit_events,
          filter: filter,
          transform: transform,
          transform_type: transform_type
        )
      end

      # List forwarders for the authenticated account.
      #
      # Offset paginated: pass +page_number+ (1-based) and +page_size+
      # (default 1000, max 1000).
      #
      # @param forwarder_type [String, nil] Restrict the listing to forwarders of
      #   this {Smplkit::Audit::ForwarderType}. Omit to list every type.
      # @param page_number [Integer, nil] 1-based page index. Omit for the first
      #   page.
      # @param page_size [Integer, nil] Maximum number of forwarders to return in
      #   this page (default 1000, max 1000).
      # @param meta_total [Boolean, nil] When +true+, populate +total+ and
      #   +total_pages+ in the returned page's +pagination+ block (costs an extra
      #   count server-side). Omit to skip it.
      # @return [ForwarderListPage] A page of the matching forwarders.
      def list(forwarder_type: nil, page_number: nil, page_size: nil, meta_total: nil)
        opts = {}
        opts[:filter_forwarder_type] = ForwarderType.coerce(forwarder_type) if forwarder_type
        opts[:page_number] = page_number if page_number
        opts[:page_size] = page_size if page_size
        opts[:meta_total] = meta_total unless meta_total.nil?

        resp = Audit.call_api { @api.list_forwarders(opts) }
        forwarders = (resp.data || []).map { |r| Forwarder.from_resource(r, client: self) }
        ForwarderListPage.new(forwarders, Audit.extract_pagination(resp.meta))
      end

      # Fetch a single forwarder by id. The returned instance is bound to this
      # client, so +forwarder.save+ and +forwarder.delete+ work. Header values
      # come back in plaintext, so mutating the returned forwarder and calling
      # +save+ preserves them without re-entering secrets.
      #
      # @param forwarder_id [String] The forwarder's id (key).
      # @return [Smplkit::Audit::Forwarder] The matching forwarder, bound to this client.
      # @raise [Smplkit::NotFoundError] If no live forwarder with that id exists.
      def get(forwarder_id)
        resp = Audit.call_api { @api.get_forwarder(forwarder_id) }
        Forwarder.from_resource(resp.data, client: self)
      end

      # Delete a forwarder.
      #
      # @param forwarder_id [String]
      # @return [nil]
      def delete(forwarder_id)
        Audit.call_api { @api.delete_forwarder(forwarder_id) }
        nil
      end

      # @api private — POST a new forwarder. Called by
      #   {Smplkit::Audit::Forwarder#save} on unsaved instances.
      def _create_forwarder(forwarder)
        if forwarder.id.nil? || forwarder.id.empty?
          raise ArgumentError, "Forwarder.id is required on create (caller-supplied key)"
        end

        resp = Audit.call_api { @api.create_forwarder(build_create_body(forwarder)) }
        Forwarder.from_resource(resp.data, client: self)
      end

      # @api private — Full-replace PUT for an existing forwarder. Called by
      #   {Smplkit::Audit::Forwarder#save} on instances with +created_at+.
      #
      # Header values come back in plaintext on the GET path, so a fetched
      # forwarder round-trips through this full-replace PUT with its header
      # values intact — no need to re-enter secrets.
      def _update_forwarder(forwarder)
        raise ArgumentError, "cannot update a Forwarder with no id" if forwarder.id.nil?

        resp = Audit.call_api { @api.update_forwarder(forwarder.id, build_body(forwarder)) }
        Forwarder.from_resource(resp.data, client: self)
      end

      private

      # Coerce a caller's +environments+ map to wrapper instances.
      #
      # Accepts either {Smplkit::Audit::ForwarderEnvironment} values or plain
      # hashes (+{ enabled: true, configuration: HttpConfiguration.new(...) }+)
      # so callers can use the lightweight hash form without importing the model.
      def normalize_environments(environments)
        return {} if environments.nil? || environments.empty?

        environments.each_with_object({}) do |(env_key, value), out|
          out[env_key.to_s] = if value.is_a?(ForwarderEnvironment)
                                value
                              else
                                ForwarderEnvironment.new(
                                  enabled: value[:enabled] || value["enabled"] || false,
                                  configuration: value[:configuration] || value["configuration"]
                                )
                              end
        end
      end

      # Convert the wrapper +environments+ map to the generated model hash.
      #
      # Per-environment +configuration+ overrides are sent as full
      # {Smplkit::Audit::HttpConfiguration} payloads (plaintext headers in),
      # mirroring the base configuration's round-trip semantics.
      def environments_to_wire(environments)
        (environments || {}).each_with_object({}) do |(env_key, env), out|
          out[env_key.to_s] = SmplkitGeneratedClient::Audit::ForwarderEnvironment.new(
            enabled: env.enabled,
            configuration: env.configuration.nil? ? nil : HttpConfiguration.to_wire(env.configuration)
          )
        end
      end

      def build_attrs(forwarder)
        # The base +enabled+ is server-pinned false; we don't send it.
        # Enablement travels entirely through +environments+.
        #
        # +forward_smplkit_events+ is an additive opt-in; only put it on the
        # wire when +true+ so the default (false) stays implicit and a
        # non-opted-in forwarder's body is unchanged. The generated model
        # defaults the field to +false+ (not nil), so it would otherwise always
        # serialize — pass +nil+ instead, which the generated +Forwarder#to_hash+
        # omits for this non-nullable attribute (mirrors the Python reference's
        # +True if forward_smplkit_events else UNSET+).
        SmplkitGeneratedClient::Audit::Forwarder.new(
          name: forwarder.name,
          description: forwarder.description,
          forwarder_type: ForwarderType.coerce(forwarder.forwarder_type),
          forward_smplkit_events: (true if forwarder.forward_smplkit_events),
          environments: environments_to_wire(forwarder.environments),
          filter: forwarder.filter,
          transform_type: TransformType.coerce(forwarder.transform_type),
          transform: forwarder.transform,
          configuration: HttpConfiguration.to_wire(forwarder.configuration)
        )
      end

      def build_create_body(forwarder)
        # Create uses the distinct ForwarderCreateRequest envelope; the audit
        # service requires data.id (the customer-supplied key) on create and
        # 409s on conflict.
        resource = SmplkitGeneratedClient::Audit::ForwarderCreateResource.new(
          id: forwarder.id.to_s,
          type: "forwarder",
          attributes: build_attrs(forwarder)
        )
        SmplkitGeneratedClient::Audit::ForwarderCreateRequest.new(data: resource)
      end

      def build_body(forwarder)
        # Update path uses the generic ForwarderRequest envelope.
        resource = SmplkitGeneratedClient::Audit::ForwarderResource.new(
          id: forwarder.id.to_s,
          type: "forwarder",
          attributes: build_attrs(forwarder)
        )
        SmplkitGeneratedClient::Audit::ForwarderRequest.new(data: resource)
      end
    end

    # A single page returned from {ForwardersClient#list}.
    #
    # @!attribute [rw] forwarders
    #   @return [Array<Smplkit::Audit::Forwarder>] Forwarders in this page.
    # @!attribute [rw] pagination
    #   @return [Hash] +meta.pagination+ block (+:page+, +:size+, and — only when
    #     the caller passed +meta_total: true+ — +:total+ / +:total_pages+).
    ForwarderListPage = Struct.new(:forwarders, :pagination) do
      include Enumerable

      def each(&) = forwarders.each(&)
      def length = forwarders.length
      alias_method :size, :length
    end
  end
end
