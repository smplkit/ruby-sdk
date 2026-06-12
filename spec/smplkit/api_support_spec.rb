# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::ApiSupport do
  describe Smplkit::ApiSupport::ErrorMapping do
    it "returns the block value on success" do
      expect(described_class.call { 42 }).to eq(42)
    end

    it "re-raises non-generated errors unchanged" do
      expect { described_class.call { raise ArgumentError, "boom" } }.to raise_error(ArgumentError, "boom")
    end

    it "maps a generated ApiError with code 0 to ConnectionError" do
      err = SmplkitGeneratedClient::Audit::ApiError.new(code: 0, response_body: "")
      expect { described_class.call { raise err } }.to raise_error(Smplkit::ConnectionError)
    end

    it "maps a generated ApiError with a nil code to ConnectionError" do
      err = SmplkitGeneratedClient::Audit::ApiError.new("network down")
      expect { described_class.call { raise err } }.to raise_error(Smplkit::ConnectionError)
    end

    it "maps a generated 404 ApiError to NotFoundError via the JSON:API body" do
      body = JSON.generate("errors" => [{ "status" => "404", "detail" => "missing" }])
      err = SmplkitGeneratedClient::Audit::ApiError.new(code: 404, response_body: body)
      expect { described_class.call { raise err } }.to raise_error(Smplkit::NotFoundError)
    end

    it "recognizes generated ApiError classes" do
      expect(described_class.generated_api_error?(SmplkitGeneratedClient::Audit::ApiError.new)).to be(true)
      expect(described_class.generated_api_error?(StandardError.new)).to be(false)
    end
  end

  describe Smplkit::ApiSupport::PaginatedFetch do
    it "returns the rows of a single short page" do
      rows = described_class.collect(page_size: 3) { |_opts| double(data: [1, 2]) }
      expect(rows).to eq([1, 2])
    end

    it "walks every page until a short one ends the run" do
      pages = [double(data: [1, 2, 3]), double(data: [4])]
      rows = described_class.collect(page_size: 3) { |opts| pages[opts[:page_number] - 1] }
      expect(rows).to eq([1, 2, 3, 4])
    end

    it "tolerates a nil data page" do
      rows = described_class.collect(page_size: 3) { |_opts| double(data: nil) }
      expect(rows).to eq([])
    end
  end

  describe Smplkit::ApiSupport::ResourceShim do
    it "deep-stringifies hash keys" do
      expect(described_class.stringify({ a: { b: 1 } })).to eq("a" => { "b" => 1 })
    end

    it "from_model returns an empty hash for nil" do
      expect(described_class.from_model(nil)).to eq({})
    end

    it "from_model deep-stringifies a model's to_hash" do
      model = double(to_hash: { id: "x", attributes: { name: "n" } })
      expect(described_class.from_model(model)).to eq("id" => "x", "attributes" => { "name" => "n" })
    end
  end
end
