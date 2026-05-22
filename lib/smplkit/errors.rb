# frozen_string_literal: true

require "json"

module Smplkit
  # A single error object from the server's JSON:API +errors+ array.
  #
  # +code+ is the application-specific machine-readable error code (e.g.
  # +environment_unmanaged+); per JSON:API §7 and ADR-014, smplkit sets
  # this on every error so callers can branch without string-matching
  # the human +detail+. +meta+ carries additional structured context
  # (e.g. <tt>{"environment" => "staging"}</tt>).
  class ApiErrorDetail
    attr_reader :status, :code, :title, :detail, :source, :meta

    def initialize(status: nil, code: nil, title: nil, detail: nil, source: nil, meta: nil)
      @status = status
      @code = code
      @title = title
      @detail = detail
      @source = source || {}
      @meta = meta || {}
    end

    def to_h
      h = {}
      h["status"] = @status unless @status.nil?
      h["code"] = @code unless @code.nil?
      h["title"] = @title unless @title.nil?
      h["detail"] = @detail unless @detail.nil?
      h["source"] = @source unless @source.empty?
      h["meta"] = @meta unless @meta.empty?
      h
    end

    def to_json(*args)
      JSON.generate(to_h, *args)
    end
  end

  # Base exception for all smplkit SDK errors.
  class Error < StandardError
    attr_reader :errors, :status_code

    def initialize(message = nil, errors: nil, status_code: nil)
      @errors = errors || []
      @status_code = status_code
      message ||= self.class.derive_message(@errors)
      super(message)
    end

    def to_s
      base = super
      return base if @errors.empty?

      if @errors.length == 1
        "#{base}\nError: #{@errors[0].to_json}"
      else
        lines = [base, "Errors:"]
        @errors.each_with_index { |err, i| lines << "  [#{i}] #{err.to_json}" }
        lines.join("\n")
      end
    end

    def self.derive_message(errors)
      return "An API error occurred" if errors.nil? || errors.empty?

      first = errors[0]
      msg = first.detail || first.title || first.status || "An API error occurred"
      extra = errors.length - 1
      msg += " (and 1 more error)" if extra == 1
      msg += " (and #{extra} more errors)" if extra > 1
      msg
    end
  end

  class ConnectionError < Error; end
  class TimeoutError < Error; end
  class NotFoundError < Error; end
  class ConflictError < Error; end
  class ValidationError < Error; end

  # Raised when the server rejects a request because the account's
  # subscription plan does not include the required entitlement.
  class PaymentRequiredError < Error; end

  module Errors
    module_function

    def parse_error_body(content)
      body = JSON.parse(content)
      raw_errors = body.is_a?(Hash) ? body["errors"] : nil
      return [] unless raw_errors.is_a?(Array)

      raw_errors.filter_map do |item|
        next unless item.is_a?(Hash)

        source = item["source"]
        meta = item["meta"]
        ApiErrorDetail.new(
          status: item["status"],
          code: item["code"],
          title: item["title"],
          detail: item["detail"],
          source: source.is_a?(Hash) ? source : {},
          meta: meta.is_a?(Hash) ? meta : {}
        )
      end
    rescue JSON::ParserError, EncodingError
      []
    end

    # Parse a non-2xx response and raise the appropriate SDK exception.
    # Raises nothing if status is 2xx.
    def raise_for_status(status_code, content)
      return if (200..299).cover?(status_code)

      errors = parse_error_body(content)
      message = errors.empty? ? "HTTP #{status_code}" : Error.derive_message(errors)

      exc_cls =
        case status_code
        when 402 then PaymentRequiredError
        when 404 then NotFoundError
        when 409 then ConflictError
        when 400, 422 then ValidationError
        else Error
        end

      raise exc_cls.new(message, errors: errors, status_code: status_code)
    end
  end
end
