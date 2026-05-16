# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Audit::ResourceTypes do
  let(:base_url) { "https://audit.example.com" }
  let(:api_key) { "sk_api_test" }
  let(:client) { Smplkit::Audit::AuditClient.new(api_key: api_key, base_url: base_url) }

  after { client._close }

  def resource_type_resource(key, created_at: "2026-04-12T15:23:01Z")
    {
      id: key,
      type: "resource_type",
      attributes: { resource_type: key, created_at: created_at }
    }
  end

  it "returns sorted rows" do
    stub_request(:get, %r{#{base_url}/api/v1/resource_types\b}).to_return(
      status: 200,
      body: { data: [resource_type_resource("account"), resource_type_resource("user")],
              meta: { pagination: { page: 1, size: 1000 } } }.to_json,
      headers: { "Content-Type" => "application/vnd.api+json" }
    )
    page = client.resource_types.list
    expect(page).to be_a(Smplkit::Audit::ResourceTypeListPage)
    expect(page.resource_types.map(&:id)).to eq(%w[account user])
    expect(page.pagination).to eq(page: 1, size: 1000)
  end

  it "forwards offset params and surfaces totals when meta_total is requested" do
    captured_uri = nil
    stub_request(:get, %r{#{base_url}/api/v1/resource_types\b})
      .with do |req|
        captured_uri = req.uri.to_s
        true
      end
      .to_return(
        status: 200,
        body: {
          data: [resource_type_resource("alpha")],
          meta: { pagination: { page: 2, size: 1, total: 3, total_pages: 3 } }
        }.to_json,
        headers: { "Content-Type" => "application/vnd.api+json" }
      )
    page = client.resource_types.list(page_number: 2, page_size: 1, meta_total: true)
    expect(captured_uri).to include("page%5Bnumber%5D=2")
    expect(captured_uri).to include("page%5Bsize%5D=1")
    expect(captured_uri).to include("meta%5Btotal%5D=true")
    expect(page.pagination).to eq(page: 2, size: 1, total: 3, total_pages: 3)
  end

  it "handles an empty response" do
    stub_request(:get, %r{#{base_url}/api/v1/resource_types\b}).to_return(
      status: 200,
      body: { data: [], meta: { pagination: { page: 1, size: 1000 } } }.to_json,
      headers: { "Content-Type" => "application/vnd.api+json" }
    )
    page = client.resource_types.list
    expect(page.resource_types).to be_empty
    expect(page.pagination).to eq(page: 1, size: 1000)
  end

  it "maps 5xx to the generic Smplkit::Error" do
    stub_request(:get, %r{#{base_url}/api/v1/resource_types\b}).to_return(
      status: 500, body: { errors: [{ status: "500" }] }.to_json,
      headers: { "Content-Type" => "application/vnd.api+json" }
    )
    expect { client.resource_types.list }.to raise_error(Smplkit::Error)
  end

  it "falls back to id when attributes.resource_type is missing" do
    # Defensive path — JSON:API guarantees +id+ is always present, so the
    # wrapper still surfaces something useful even if the server ever
    # omits +attributes.resource_type+. We build a stand-in here because
    # the generated +ResourceTypeAttributes+ rejects nil on construction.
    fake_attrs = Struct.new(:resource_type, :created_at).new(nil, "2026-04-12T15:23:01Z")
    fake_resource = Struct.new(:id, :attributes).new("smpl.flag", fake_attrs)
    rt = Smplkit::Audit::ResourceType.from_resource(fake_resource)
    expect(rt.resource_type).to eq("smpl.flag")
  end
end
