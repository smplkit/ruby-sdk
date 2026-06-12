# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Account::AccountClient do
  subject(:account) { described_class.new(api_key: "k", base_url: base_url) }

  let(:base_url) { "https://app.smplkit.test" }
  let(:path) { "#{base_url}/api/v1/accounts/current/settings" }
  let(:json) { { "Content-Type" => "application/json" } }

  describe "#settings.get" do
    it "fetches and wraps the raw settings object" do
      stub = stub_request(:get, path)
             .with(headers: { "Authorization" => "Bearer k" })
             .to_return(status: 200, body: JSON.generate("environment_order" => %w[production staging], "x" => 1),
                        headers: json)
      settings = account.settings.get
      expect(settings).to be_a(Smplkit::Account::AccountSettings)
      expect(settings.environment_order).to eq(%w[production staging])
      expect(settings.raw["x"]).to eq(1)
      expect(stub).to have_been_requested
    end

    it "tolerates an empty body" do
      stub_request(:get, path).to_return(status: 200, body: "")
      expect(account.settings.get.raw).to eq({})
    end

    it "tolerates a non-object JSON body" do
      stub_request(:get, path).to_return(status: 200, body: "[]", headers: json)
      expect(account.settings.get.raw).to eq({})
    end

    it "maps a 404 to NotFoundError" do
      stub_request(:get, path).to_return(status: 404, body: JSON.generate("errors" => [{ "status" => "404" }]))
      expect { account.settings.get }.to raise_error(Smplkit::NotFoundError)
    end
  end

  describe "settings.save" do
    it "PUTs the full settings object and refreshes from the response" do
      stub_request(:get, path)
        .to_return(status: 200, body: JSON.generate("environment_order" => %w[production]), headers: json)
      put_stub = stub_request(:put, path)
                 .with(body: hash_including("environment_order" => %w[production staging]))
                 .to_return(status: 200, body: JSON.generate("environment_order" => %w[production staging]),
                            headers: json)
      settings = account.settings.get
      settings.environment_order = %w[production staging]
      settings.save
      expect(put_stub).to have_been_requested
      expect(settings.environment_order).to eq(%w[production staging])
    end
  end

  it "close is a no-op" do
    expect(account.close).to be_nil
  end

  it "open yields the client and closes on exit" do
    yielded = nil
    described_class.open(api_key: "k", base_url: base_url) { |c| yielded = c }
    expect(yielded).to be_a(described_class)
  end

  describe ".resolve_account_target" do
    it "resolves the app url from base_domain/scheme when base_url is nil" do
      url, key, headers = Smplkit::Account.resolve_account_target(
        api_key: "k", base_url: nil, profile: nil, base_domain: "smplkit.test",
        scheme: "https", debug: false, extra_headers: { "X-A" => "b" }
      )
      expect(url).to eq("https://app.smplkit.test")
      expect(key).to eq("k")
      expect(headers).to eq("X-A" => "b")
    end

    it "uses an explicit base_url directly and strips a trailing slash" do
      url, = Smplkit::Account.resolve_account_target(
        api_key: "k", base_url: "https://app.example.com/", profile: nil, base_domain: "smplkit.test",
        scheme: "https", debug: false, extra_headers: nil
      )
      expect(url).to eq("https://app.example.com")
    end
  end
end
