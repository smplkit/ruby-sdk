# frozen_string_literal: true

module Smplkit
  module Audit
    # +client.audit.categories.list+ — distinct +category+ values seen for
    # the account.
    #
    # Backed by a maintain-by-write side table populated whenever an event
    # is recorded with a non-null +category+ (ADR-047 §2.5), so the response
    # time is independent of how many years of events the account has
    # accumulated. Sorted alphabetically; offset pagination (+page_number+ /
    # +page_size+) per ADR-014.
    class Categories
      def initialize(api)
        @api = api
      end

      # +environments+ is an optional array of environment keys (and/or the
      # reserved +"smplkit"+ control-plane bucket) used to scope the read;
      # the values are comma-joined into +filter[environment]+. Omitting it
      # (or passing an empty array) leaves the filter unset — identical to
      # the prior behavior on the wire.
      def list(page_number: nil, page_size: nil, meta_total: nil, environments: nil)
        opts = {}
        opts[:page_number] = page_number if page_number
        opts[:page_size] = page_size if page_size
        opts[:meta_total] = meta_total unless meta_total.nil?
        joined_environments = Smplkit::Audit.join_environments(environments)
        opts[:filter_environment] = joined_environments if joined_environments

        resp = Smplkit::Audit.call_api { @api.list_categories(opts) }
        rows = (resp.data || []).map { |r| Category.from_resource(r) }
        CategoryListPage.new(rows, Smplkit::Audit.extract_pagination(resp.meta))
      end
    end

    CategoryListPage = Struct.new(:categories, :pagination)
  end
end
