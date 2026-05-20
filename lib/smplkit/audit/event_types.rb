# frozen_string_literal: true

module Smplkit
  module Audit
    # +client.audit.event_types.list+ — distinct +event_type+ slugs seen for
    # the account.
    #
    # Without +filter_resource_type+, returns one row per distinct
    # event type — an event type recorded with multiple resource_types appears
    # once. With the filter, returns the event types seen with that
    # specific resource_type, powering the cascading-filter behavior
    # on the Activity tab.
    #
    # ADR-047 §2.5. Sorted alphabetically; offset pagination
    # (+page_number+ / +page_size+) per ADR-014.
    class EventTypes
      def initialize(api)
        @api = api
      end

      def list(filter_resource_type: nil, page_number: nil, page_size: nil, meta_total: nil)
        opts = {}
        opts[:filter_resource_type] = filter_resource_type if filter_resource_type
        opts[:page_number] = page_number if page_number
        opts[:page_size] = page_size if page_size
        opts[:meta_total] = meta_total unless meta_total.nil?

        resp = Smplkit::Audit.call_api { @api.list_event_types(opts) }
        rows = (resp.data || []).map { |r| EventType.from_resource(r) }
        EventTypeListPage.new(rows, Smplkit::Audit.extract_pagination(resp.meta))
      end
    end

    EventTypeListPage = Struct.new(:event_types, :pagination)
  end
end
