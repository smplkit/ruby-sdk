# frozen_string_literal: true

module Smplkit
  module Audit
    # +client.audit.resource_types.list+ — distinct +resource_type+ slugs
    # seen for the account.
    #
    # Response time is independent of how many years of events the account has
    # accumulated. Sorted alphabetically; offset paginated.
    class ResourceTypes
      def initialize(api, environment: nil)
        @api = api
        @environment = environment
      end

      # List the distinct +resource_type+ slugs seen in the account.
      #
      # +environments+ scopes the listing to a set of environments: pass an
      # array of environment keys and/or the reserved +"smplkit"+ control-plane
      # bucket; the values are comma-joined into +filter[environment]+. Omit it
      # (the default) to scope the listing to the client's configured
      # environment; with no configured environment the filter is left off
      # entirely.
      #
      # @param page_number [Integer, nil] 1-based page index. Omit for the first
      #   page.
      # @param page_size [Integer, nil] Maximum number of slugs to return in this
      #   page.
      # @param meta_total [Boolean, nil] When +true+, populate +total+ and
      #   +total_pages+ in the returned page's +pagination+ block (costs an extra
      #   count server-side). Omit to skip it.
      # @param environments [Array<String>, nil] Environment keys and/or the
      #   reserved +"smplkit"+ control-plane bucket to scope the listing to. Omit
      #   to fall back to the client's configured environment; with no configured
      #   environment the filter is left off entirely.
      # @return [Smplkit::Audit::ResourceTypeListPage] A page of the matching
      #   resource-type slugs.
      def list(page_number: nil, page_size: nil, meta_total: nil, environments: nil)
        opts = {}
        opts[:page_number] = page_number if page_number
        opts[:page_size] = page_size if page_size
        opts[:meta_total] = meta_total unless meta_total.nil?
        resolved_environment = Smplkit::Audit.resolve_environment_filter(environments, @environment)
        opts[:filter_environment] = resolved_environment if resolved_environment

        resp = Smplkit::Audit.call_api { @api.list_resource_types(opts) }
        rows = (resp.data || []).map { |r| ResourceType.from_resource(r) }
        ResourceTypeListPage.new(rows, Smplkit::Audit.extract_pagination(resp.meta))
      end
    end

    ResourceTypeListPage = Struct.new(:resource_types, :pagination)
  end
end
