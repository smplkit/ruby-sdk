# frozen_string_literal: true

require "json"

module Smplkit
  # A single error object from the server's JSON:API +errors+ array.
  class ApiErrorDetail
    attr_reader :status, :title, :detail, :source

    def initialize(status: nil, title: nil, detail: nil, source: nil)
      @status = status
      @title = title
      @detail = detail
      @source = source || {}
    end

    def to_h
      h = {}
      h["status"] = @status unless @status.nil?
      h["title"] = @title unless @title.nil?
      h["detail"] = @detail unless @detail.nil?
      h["source"] = @source unless @source.empty?
      h
    end

    def to_json(*)
      JSON.generate(to_h, *)
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

  module Errors
    module_function

    def parse_error_body(content)
      body = JSON.parse(content)
      raw_errors = body.is_a?(Hash) ? body["errors"] : nil
      return [] unless raw_errors.is_a?(Array)

      raw_errors.filter_map do |item|
        next unless item.is_a?(Hash)

        ApiErrorDetail.new(
          status: item["status"],
          title: item["title"],
          detail: item["detail"],
          source: item["source"] || {}
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
        when 404 then NotFoundError
        when 409 then ConflictError
        when 400, 422 then ValidationError
        else Error
        end

      raise exc_cls.new(message, errors: errors, status_code: status_code)
    end
  end
end
