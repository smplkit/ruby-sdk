# frozen_string_literal: true

module Smplkit
  # Ruby-internal adapters bridging the generated client layer to the wrapper.
  module ApiSupport
    # Default page[size] the runtime asks for when walking a list endpoint to
    # completion. The platform caps page[size] at 1000; using the same value
    # here makes the minimum number of round-trips per exhaustive fetch.
    RUNTIME_PAGE_SIZE = 1000

    # Wraps a generated-API call and converts any +ApiError+ raised by the
    # generated layer into the +Smplkit::Error+ hierarchy. Connection-level
    # failures (no response from the server) become +Smplkit::ConnectionError+;
    # status-coded failures route through +Errors.raise_for_status+ which emits
    # +NotFoundError+ / +ConflictError+ / +ValidationError+ / +Error+ depending
    # on the JSON:API body.
    module ErrorMapping
      module_function

      def call
        yield
      rescue StandardError => e
        raise unless generated_api_error?(e)

        raise Smplkit::ConnectionError, e.message.to_s if e.code.nil? || e.code.zero?

        Smplkit::Errors.raise_for_status(e.code, e.response_body.to_s)
        # raise_for_status only returns on 2xx; if we get here the generated
        # layer raised on a 2xx (shouldn't happen) so re-raise the original.
        raise
      end

      def generated_api_error?(err)
        klass_name = err.class.name.to_s
        klass_name.start_with?("SmplkitGeneratedClient::") && klass_name.end_with?("::ApiError")
      end
    end

    # Walk a generated paginated list endpoint to completion.
    #
    # The block receives a per-page +opts+ hash with +page_number+ and
    # +page_size+ filled in, calls the generated list method through
    # {ErrorMapping.call}, and returns the response object. Pages stop when the
    # server returns fewer rows than requested — the platform's standard
    # last-page signal across every offset-paginated list endpoint. Returns the
    # concatenated +response.data+ rows.
    module PaginatedFetch
      module_function

      def collect(page_size: RUNTIME_PAGE_SIZE)
        rows = []
        page_number = 1
        loop do
          opts = { page_number: page_number, page_size: page_size }
          response = ErrorMapping.call { yield(opts) }
          page = response.data || []
          rows.concat(page)
          break if page.length < page_size

          page_number += 1
        end
        rows
      end
    end

    # Deep-stringify Hash keys so resources returned by generated +to_hash+
    # (symbol-keyed) match what the wrapper helpers expect (string-keyed).
    module ResourceShim
      module_function

      def stringify(value)
        Smplkit::Helpers.deep_stringify_keys(value)
      end

      # Convenience: produce a string-keyed Hash from a generated model.
      def from_model(model)
        return {} if model.nil?

        stringify(model.to_hash)
      end
    end
  end
end
