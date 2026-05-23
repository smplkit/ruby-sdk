# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Errors do
  describe ".raise_for_status" do
    it "no-ops on 2xx" do
      expect { described_class.raise_for_status(200, "") }.not_to raise_error
      expect { described_class.raise_for_status(204, "") }.not_to raise_error
    end

    it "raises PaymentRequiredError on 402" do
      body = JSON.generate("errors" => [{ "status" => "402", "detail" => "plan required" }])
      expect { described_class.raise_for_status(402, body) }
        .to raise_error(Smplkit::PaymentRequiredError, /plan required/)
    end

    it "raises NotFoundError on 404" do
      body = JSON.generate("errors" => [{ "status" => "404", "detail" => "missing" }])
      expect { described_class.raise_for_status(404, body) }.to raise_error(Smplkit::NotFoundError, /missing/)
    end

    it "raises ConflictError on 409" do
      body = JSON.generate("errors" => [{ "status" => "409", "title" => "Conflict" }])
      expect { described_class.raise_for_status(409, body) }.to raise_error(Smplkit::ConflictError, /Conflict/)
    end

    it "raises ValidationError on 400/422" do
      body = JSON.generate("errors" => [{ "status" => "422", "detail" => "bad" }])
      expect { described_class.raise_for_status(400, body) }.to raise_error(Smplkit::ValidationError)
      expect { described_class.raise_for_status(422, body) }.to raise_error(Smplkit::ValidationError)
    end

    it "falls back to base Error for unknown status" do
      expect { described_class.raise_for_status(500, "") }.to raise_error(Smplkit::Error)
    end

    it "tolerates malformed JSON bodies" do
      expect { described_class.raise_for_status(500, "not json") }.to raise_error(Smplkit::Error, /HTTP 500/)
    end
  end

  describe Smplkit::Error do
    it "exposes errors and status code" do
      detail = Smplkit::ApiErrorDetail.new(status: "400", detail: "bad", title: "Bad")
      err = described_class.new("oops", errors: [detail], status_code: 400)
      expect(err.errors).to eq([detail])
      expect(err.status_code).to eq(400)
      expect(err.to_s).to start_with("oops")
      expect(err.to_s).to include("Error: ")
    end

    it "lists multiple errors with indices" do
      details = [
        Smplkit::ApiErrorDetail.new(status: "400", detail: "first"),
        Smplkit::ApiErrorDetail.new(status: "400", detail: "second"),
        Smplkit::ApiErrorDetail.new(status: "400", detail: "third")
      ]
      err = described_class.new(errors: details)
      str = err.to_s
      expect(str).to include("[0]")
      expect(str).to include("[1]")
      expect(str).to include("[2]")
    end

    it "derives message from errors when none given" do
      detail = Smplkit::ApiErrorDetail.new(detail: "the bad thing")
      err = described_class.new(errors: [detail])
      expect(err.to_s).to start_with("the bad thing")
    end

    it "derives message with extras count" do
      details = Array.new(3) { |i| Smplkit::ApiErrorDetail.new(detail: "err#{i}") }
      err = described_class.new(errors: details)
      expect(err.to_s).to include("(and 2 more errors)")

      single_extra = [
        Smplkit::ApiErrorDetail.new(detail: "first"),
        Smplkit::ApiErrorDetail.new(detail: "second")
      ]
      err2 = described_class.new(errors: single_extra)
      expect(err2.to_s).to include("(and 1 more error)")
    end
  end

  describe Smplkit::ApiErrorDetail do
    it "serializes only present fields" do
      detail = described_class.new(status: "400")
      expect(detail.to_h).to eq("status" => "400")
      expect(JSON.parse(detail.to_json)).to eq("status" => "400")
    end

    it "round-trips code and meta" do
      # Regression: code + meta were dropped by the parser/model so
      # callers couldn't branch on machine-readable codes like
      # environment_unmanaged without string-matching detail.
      detail = described_class.new(
        status: "400",
        code: "environment_unmanaged",
        title: "Environment is unmanaged",
        meta: { "environment" => "staging" }
      )
      expect(detail.code).to eq("environment_unmanaged")
      expect(detail.meta).to eq("environment" => "staging")
      expect(JSON.parse(detail.to_json)).to include(
        "code" => "environment_unmanaged",
        "meta" => { "environment" => "staging" }
      )
    end
  end

  describe ".parse_error_body" do
    it "extracts code and meta from the JSON:API errors array" do
      body = JSON.generate(
        "errors" => [
          {
            "status" => "400",
            "code" => "environment_unmanaged",
            "detail" => "Promote it first.",
            "meta" => { "environment" => "staging", "count" => 2 }
          }
        ]
      )
      details = described_class.parse_error_body(body)
      expect(details.length).to eq(1)
      expect(details[0].code).to eq("environment_unmanaged")
      expect(details[0].meta).to eq("environment" => "staging", "count" => 2)
    end

    it "defensively coerces non-hash source/meta to empty hashes" do
      body = JSON.generate(
        "errors" => [
          { "status" => "400", "title" => "Bad", "source" => "x", "meta" => "y" }
        ]
      )
      details = described_class.parse_error_body(body)
      expect(details[0].source).to eq({})
      expect(details[0].meta).to eq({})
    end
  end
end
