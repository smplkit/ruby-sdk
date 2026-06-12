# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Audit do
  describe ".call_api" do
    it "re-raises the original ApiError when the generated layer raised on a 2xx code" do
      # raise_for_status only returns on a 2xx status; if the generated layer
      # raised an ApiError carrying a 2xx code (which it never should), the
      # mapper falls through to its defensive `raise` and re-raises the
      # original error unchanged.
      original = SmplkitGeneratedClient::Audit::ApiError.new(code: 200, response_body: "")
      expect do
        described_class.call_api { raise original }
      end.to raise_error(SmplkitGeneratedClient::Audit::ApiError) do |raised|
        expect(raised).to be(original)
      end
    end
  end
end

RSpec.describe Smplkit::Audit::HttpMethod do
  describe ".coerce" do
    it "returns nil for nil input" do
      expect(described_class.coerce(nil)).to be_nil
    end

    it "passes through a known verb" do
      expect(described_class.coerce("POST")).to eq("POST")
    end

    it "raises ArgumentError for an unknown verb" do
      expect { described_class.coerce("TRACE") }
        .to raise_error(ArgumentError, /Unknown HttpMethod/)
    end
  end
end

RSpec.describe Smplkit::Audit::HttpConfiguration do
  describe ".to_wire" do
    it "accepts headers provided as plain Hashes" do
      config = described_class.new(
        method: "POST",
        url: "https://example.test/hook",
        headers: [{ "name" => "X-Api-Key", "value" => "secret" }]
      )
      wire = described_class.to_wire(config)
      header = wire.headers.first
      expect(header.name).to eq("X-Api-Key")
      expect(header.value).to eq("secret")
    end

    it "accepts headers provided as symbol-keyed Hashes" do
      wire = described_class.to_wire(
        method: "POST",
        url: "https://example.test/hook",
        headers: [{ name: "Authorization", value: "Bearer t" }]
      )
      header = wire.headers.first
      expect(header.name).to eq("Authorization")
      expect(header.value).to eq("Bearer t")
    end

    it "accepts headers provided as HttpHeader objects" do
      config = described_class.new(
        method: "POST",
        url: "https://example.test/hook",
        headers: [Smplkit::Audit::HttpHeader.new(name: "X-Trace", value: "1")]
      )
      wire = described_class.to_wire(config)
      expect(wire.headers.first.name).to eq("X-Trace")
    end
  end
end
