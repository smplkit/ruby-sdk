# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Audit::Categories do
  let(:base_url) { "https://audit.example.com" }
  let(:api_key) { "sk_api_test" }
  let(:client) { Smplkit::Audit::AuditClient.new(api_key: api_key, base_url: base_url) }

  after { client._close }

  def category_resource(key, created_at: "2026-04-12T15:23:01Z")
    {
      id: key,
      type: "category",
      attributes: { category: key, created_at: created_at }
    }
  end

  it "returns sorted rows" do
    stub_request(:get, %r{#{base_url}/api/v1/categories\b}).to_return(
      status: 200,
      body: { data: [category_resource("auth"), category_resource("billing")],
              meta: { pagination: { page: 1, size: 1000 } } }.to_json,
      headers: { "Content-Type" => "application/vnd.api+json" }
    )
    page = client.categories.list
    expect(page).to be_a(Smplkit::Audit::CategoryListPage)
    expect(page.categories.map(&:id)).to eq(%w[auth billing])
    expect(page.categories.map(&:category)).to eq(%w[auth billing])
    expect(page.pagination).to eq(page: 1, size: 1000)
  end

  it "forwards offset params and surfaces totals when meta_total is requested" do
    captured_uri = nil
    stub_request(:get, %r{#{base_url}/api/v1/categories\b})
      .with do |req|
        captured_uri = req.uri.to_s
        true
      end
      .to_return(
        status: 200,
        body: {
          data: [category_resource("auth")],
          meta: { pagination: { page: 2, size: 1, total: 3, total_pages: 3 } }
        }.to_json,
        headers: { "Content-Type" => "application/vnd.api+json" }
      )
    page = client.categories.list(page_number: 2, page_size: 1, meta_total: true)
    expect(captured_uri).to include("page%5Bnumber%5D=2")
    expect(captured_uri).to include("page%5Bsize%5D=1")
    expect(captured_uri).to include("meta%5Btotal%5D=true")
    expect(page.pagination).to eq(page: 2, size: 1, total: 3, total_pages: 3)
  end

  it "handles an empty response" do
    stub_request(:get, %r{#{base_url}/api/v1/categories\b}).to_return(
      status: 200,
      body: { data: [], meta: { pagination: { page: 1, size: 1000 } } }.to_json,
      headers: { "Content-Type" => "application/vnd.api+json" }
    )
    page = client.categories.list
    expect(page.categories).to be_empty
    expect(page.pagination).to eq(page: 1, size: 1000)
  end

  it "maps 5xx to the generic Smplkit::Error" do
    stub_request(:get, %r{#{base_url}/api/v1/categories\b}).to_return(
      status: 500, body: { errors: [{ status: "500" }] }.to_json,
      headers: { "Content-Type" => "application/vnd.api+json" }
    )
    expect { client.categories.list }.to raise_error(Smplkit::Error)
  end

  it "falls back to id when attributes.category is missing" do
    # Defensive path — JSON:API guarantees +id+ is always present, so the
    # wrapper still surfaces something useful even if the server ever omits
    # +attributes.category+. We build a stand-in here because the generated
    # +CategoryAttributes+ rejects nil on construction.
    fake_attrs = Struct.new(:category, :created_at).new(nil, "2026-04-12T15:23:01Z")
    fake_resource = Struct.new(:id, :attributes).new("billing", fake_attrs)
    c = Smplkit::Audit::Category.from_resource(fake_resource)
    expect(c.category).to eq("billing")
  end

  describe "filter[environment]" do
    def stub_capture(&capture)
      stub_request(:get, %r{#{base_url}/api/v1/categories\b})
        .with(&capture)
        .to_return(
          status: 200,
          body: { data: [], meta: { pagination: { page: 1, size: 1000 } } }.to_json,
          headers: { "Content-Type" => "application/vnd.api+json" }
        )
    end

    it "omits filter[environment] by default" do
      captured_uri = nil
      stub_capture do |req|
        captured_uri = req.uri.to_s
        true
      end
      client.categories.list
      expect(captured_uri).not_to include("filter%5Benvironment%5D")
    end

    it "omits filter[environment] for an empty array" do
      captured_uri = nil
      stub_capture do |req|
        captured_uri = req.uri.to_s
        true
      end
      client.categories.list(environments: [])
      expect(captured_uri).not_to include("filter%5Benvironment%5D")
    end

    it "passes a single environment value through" do
      captured_uri = nil
      stub_capture do |req|
        captured_uri = req.uri.to_s
        true
      end
      client.categories.list(environments: ["production"])
      expect(captured_uri).to include("filter%5Benvironment%5D=production")
    end

    it "comma-joins multiple environment values" do
      captured_uri = nil
      stub_capture do |req|
        captured_uri = req.uri.to_s
        true
      end
      client.categories.list(environments: %w[production staging])
      expect(captured_uri).to include("filter%5Benvironment%5D=production,staging")
    end

    it "accepts the reserved smplkit bucket" do
      captured_uri = nil
      stub_capture do |req|
        captured_uri = req.uri.to_s
        true
      end
      client.categories.list(environments: ["smplkit"])
      expect(captured_uri).to include("filter%5Benvironment%5D=smplkit")
    end
  end
end
