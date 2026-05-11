# frozen_string_literal: true

module Smplkit
  module Audit
    # +client.audit.resource_types.list+ — distinct +resource_type+ slugs
    # seen for the account.
    #
    # Backed by a maintain-by-write side table (ADR-047 §2.5), so the
    # response time is independent of how many years of events the
    # account has accumulated. Sorted alphabetically; cursor pagination
    # via +page_after+.
    class ResourceTypes
      def initialize(api)
        @api = api
      end

      def list(page_size: nil, page_after: nil)
        opts = {}
        opts[:page_size] = page_size if page_size
        opts[:page_after] = page_after if page_after

        resp = Smplkit::Audit.call_api { @api.list_resource_types(opts) }
        rows = (resp.data || []).map { |r| ResourceType.from_resource(r) }
        ResourceTypeListPage.new(rows, Smplkit::Audit.next_cursor(resp.links&._next))
      end
    end

    ResourceTypeListPage = Struct.new(:resource_types, :next_cursor)
  end
end
