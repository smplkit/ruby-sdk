# frozen_string_literal: true

module Smplkit
  module Audit
    # +client.audit.actions.list+ — distinct +action+ slugs seen for
    # the account.
    #
    # Without +filter_resource_type+, returns one row per distinct
    # action — an action recorded with multiple resource_types appears
    # once. With the filter, returns the actions seen with that
    # specific resource_type, powering the cascading-filter behavior
    # on the Activity tab.
    #
    # ADR-047 §2.5. Sorted alphabetically; cursor pagination via
    # +page_after+.
    class Actions
      def initialize(api)
        @api = api
      end

      def list(filter_resource_type: nil, page_size: nil, page_after: nil)
        opts = {}
        opts[:filter_resource_type] = filter_resource_type if filter_resource_type
        opts[:page_size] = page_size if page_size
        opts[:page_after] = page_after if page_after

        resp = Smplkit::Audit.call_api { @api.list_actions(opts) }
        rows = (resp.data || []).map { |r| Action.from_resource(r) }
        ActionListPage.new(rows, Smplkit::Audit.next_cursor(resp.links&._next))
      end
    end

    ActionListPage = Struct.new(:actions, :next_cursor)
  end
end
