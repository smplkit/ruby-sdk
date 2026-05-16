# frozen_string_literal: true

module Smplkit
  module Audit
    # +client.audit.resource_types.list+ — distinct +resource_type+ slugs
    # seen for the account.
    #
    # Backed by a maintain-by-write side table (ADR-047 §2.5), so the
    # response time is independent of how many years of events the
    # account has accumulated. Sorted alphabetically; offset pagination
    # (+page_number+ / +page_size+) per ADR-014.
    class ResourceTypes
      def initialize(api)
        @api = api
      end

      def list(page_number: nil, page_size: nil, meta_total: nil)
        opts = {}
        opts[:page_number] = page_number if page_number
        opts[:page_size] = page_size if page_size
        opts[:meta_total] = meta_total unless meta_total.nil?

        resp = Smplkit::Audit.call_api { @api.list_resource_types(opts) }
        rows = (resp.data || []).map { |r| ResourceType.from_resource(r) }
        ResourceTypeListPage.new(rows, Smplkit::Audit.extract_pagination(resp.meta))
      end
    end

    ResourceTypeListPage = Struct.new(:resource_types, :pagination)
  end
end
