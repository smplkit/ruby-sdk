# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Audit::Actions do
  let(:base_url) { "https://audit.example.com" }
  let(:api_key) { "sk_api_test" }
  let(:client) { Smplkit::Audit::AuditClient.new(api_key: api_key, base_url: base_url) }

  after { client._close }

  def action_resource(key, created_at: "2026-04-12T15:23:01Z")
    {
      id: key,
      type: "action",
      attributes: { action: key, created_at: created_at }
    }
  end

  it "returns sorted rows when unfiltered" do
    captured_uri = nil
    stub_request(:get, %r{#{base_url}/api/v1/actions\b})
      .with do |req|
        captured_uri = req.uri.to_s
        true
      end
      .to_return(
        status: 200,
        body: { data: [action_resource("account.updated"), action_resource("user.login")],
                meta: { pagination: { page: 1, size: 1000 } } }.to_json,
        headers: { "Content-Type" => "application/vnd.api+json" }
      )
    page = client.actions.list
    expect(page).to be_a(Smplkit::Audit::ActionListPage)
    expect(page.actions.map(&:id)).to eq(%w[account.updated user.login])
    expect(captured_uri).not_to include("filter%5Bresource_type%5D")
    expect(page.pagination).to eq(page: 1, size: 1000)
  end

  it "passes filter[resource_type] through to the generated client" do
    captured_uri = nil
    stub_request(:get, %r{#{base_url}/api/v1/actions\b})
      .with do |req|
        captured_uri = req.uri.to_s
        true
      end
      .to_return(
        status: 200,
        body: { data: [action_resource("user.login")], meta: { pagination: { page: 1, size: 1000 } } }.to_json,
        headers: { "Content-Type" => "application/vnd.api+json" }
      )
    page = client.actions.list(filter_resource_type: "user")
    expect(captured_uri).to include("filter%5Bresource_type%5D=user")
    expect(page.actions.first.id).to eq("user.login")
  end

  it "forwards offset params and surfaces totals when meta_total is requested" do
    captured_uri = nil
    stub_request(:get, %r{#{base_url}/api/v1/actions\b})
      .with do |req|
        captured_uri = req.uri.to_s
        true
      end
      .to_return(
        status: 200,
        body: {
          data: [action_resource("a.x")],
          meta: { pagination: { page: 2, size: 1, total: 3, total_pages: 3 } }
        }.to_json,
        headers: { "Content-Type" => "application/vnd.api+json" }
      )
    page = client.actions.list(page_number: 2, page_size: 1, meta_total: true, filter_resource_type: "user")
    expect(captured_uri).to include("page%5Bnumber%5D=2")
    expect(captured_uri).to include("page%5Bsize%5D=1")
    expect(captured_uri).to include("meta%5Btotal%5D=true")
    expect(page.pagination).to eq(page: 2, size: 1, total: 3, total_pages: 3)
  end

  it "handles an empty response" do
    stub_request(:get, %r{#{base_url}/api/v1/actions\b}).to_return(
      status: 200, body: { data: [], meta: { pagination: { page: 1, size: 1000 } } }.to_json,
      headers: { "Content-Type" => "application/vnd.api+json" }
    )
    page = client.actions.list
    expect(page.actions).to be_empty
    expect(page.pagination).to eq(page: 1, size: 1000)
  end

  it "falls back to id when attributes.action is missing" do
    # Defensive path — JSON:API guarantees +id+ is always present, so the
    # wrapper still surfaces something useful even if the server ever
    # omits +attributes.action+. We build a stand-in here because the
    # generated +ActionAttributes+ rejects nil on construction.
    fake_attrs = Struct.new(:action, :created_at).new(nil, "2026-04-12T15:23:01Z")
    fake_resource = Struct.new(:id, :attributes).new("x.y", fake_attrs)
    a = Smplkit::Audit::Action.from_resource(fake_resource)
    expect(a.action).to eq("x.y")
  end
end
