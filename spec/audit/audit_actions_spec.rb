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
                meta: { page_size: 50 } }.to_json,
        headers: { "Content-Type" => "application/vnd.api+json" }
      )
    page = client.actions.list
    expect(page).to be_a(Smplkit::Audit::ActionListPage)
    expect(page.actions.map(&:id)).to eq(%w[account.updated user.login])
    expect(captured_uri).not_to include("filter%5Bresource_type%5D")
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
        body: { data: [action_resource("user.login")], meta: { page_size: 50 } }.to_json,
        headers: { "Content-Type" => "application/vnd.api+json" }
      )
    page = client.actions.list(filter_resource_type: "user")
    expect(captured_uri).to include("filter%5Bresource_type%5D=user")
    expect(page.actions.first.id).to eq("user.login")
  end

  it "extracts the cursor from links.next with trailing filter params" do
    stub_request(:get, %r{#{base_url}/api/v1/actions\b}).to_return(
      status: 200,
      body: {
        data: [action_resource("a.x")],
        links: { next: "/api/v1/actions?page[size]=1&page[after]=tok-2&filter[resource_type]=user" },
        meta: { page_size: 1 }
      }.to_json,
      headers: { "Content-Type" => "application/vnd.api+json" }
    )
    page = client.actions.list(page_size: 1, filter_resource_type: "user")
    expect(page.next_cursor).to eq("tok-2")
  end

  it "returns nil next_cursor when the server omits links.next" do
    stub_request(:get, %r{#{base_url}/api/v1/actions\b}).to_return(
      status: 200, body: { data: [], meta: { page_size: 50 } }.to_json,
      headers: { "Content-Type" => "application/vnd.api+json" }
    )
    page = client.actions.list
    expect(page.next_cursor).to be_nil
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
