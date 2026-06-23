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
  describe "defaults and header helpers" do
    it "defaults method / success_status / tls_verify and an empty headers map" do
      cfg = described_class.new(url: "https://x")
      expect(cfg.method).to eq("POST")
      expect(cfg.success_status).to eq("2xx")
      expect(cfg.tls_verify).to be(true)
      expect(cfg.ca_cert).to be_nil
      expect(cfg.headers).to eq({})
    end

    it "set_header / get_header read and write individual headers by name" do
      cfg = described_class.new(url: "https://x")
      cfg.set_header("DD-API-KEY", "secret")
      expect(cfg.get_header("DD-API-KEY")).to eq("secret")
      expect(cfg.get_header("Absent")).to be_nil
    end

    it "stringifies header keys passed to the constructor so get_header works by name" do
      cfg = described_class.new(url: "https://x", headers: { "DD-API-KEY": "secret" })
      expect(cfg.get_header("DD-API-KEY")).to eq("secret")
    end
  end

  describe ".to_wire" do
    it "serializes the name→value headers object onto the generated config" do
      config = described_class.new(
        method: "POST",
        url: "https://example.test/hook",
        headers: { "X-Api-Key" => "secret" }
      )
      wire = described_class.to_wire(config)
      expect(wire).to be_a(SmplkitGeneratedClient::Audit::ForwarderHttpConfiguration)
      expect(wire.url).to eq("https://example.test/hook")
      expect(wire.headers).to eq("X-Api-Key" => "secret")
    end

    it "accepts a Hash (not just a struct) and stringifies header keys" do
      wire = described_class.to_wire(
        url: "https://example.test/hook",
        headers: { Authorization: "Bearer t" }
      )
      expect(wire.headers).to eq("Authorization" => "Bearer t")
    end
  end

  describe ".from_wire" do
    it "returns a default configuration for nil" do
      cfg = described_class.from_wire(nil)
      expect(cfg.method).to eq("POST")
      expect(cfg.url).to eq("")
      expect(cfg.headers).to eq({})
      expect(cfg.success_status).to eq("2xx")
      expect(cfg.tls_verify).to be(true)
    end

    it "stringifies symbol header keys the generated client returns" do
      wire = SmplkitGeneratedClient::Audit::ForwarderHttpConfiguration.new(
        method: "POST", url: "https://x", headers: { "DD-API-KEY": "<redacted>" },
        success_status: "2xx", tls_verify: nil, ca_cert: nil
      )
      cfg = described_class.from_wire(wire)
      expect(cfg.get_header("DD-API-KEY")).to eq("<redacted>")
      expect(cfg.tls_verify).to be(true) # nil on the wire defaults to verifying
    end

    it "preserves an explicit tls_verify false" do
      wire = SmplkitGeneratedClient::Audit::ForwarderHttpConfiguration.new(
        method: "POST", url: "https://x", headers: {}, success_status: "2xx",
        tls_verify: false, ca_cert: nil
      )
      expect(described_class.from_wire(wire).tls_verify).to be(false)
    end
  end
end

RSpec.describe Smplkit::Audit::ForwarderEnvironment do
  describe "#to_payload" do
    it "emits the flat sparse overlay: enabled plus only overridden leaves and headers.<name>" do
      env = described_class.new(enabled: true, url: "https://prod")
      env.set_header("DD-API-KEY", "prod-secret")
      expect(env.to_payload).to eq(
        "enabled" => true,
        "url" => "https://prod",
        "headers.DD-API-KEY" => "prod-secret"
      )
    end

    it "emits only enabled when nothing else is overridden" do
      expect(described_class.new(enabled: false).to_payload).to eq("enabled" => false)
    end
  end

  describe ".from_flat" do
    it "returns a disabled, override-free environment for nil" do
      env = described_class.from_flat(nil)
      expect(env.enabled).to be(false)
      expect(env.url).to be_nil
      expect(env.headers).to eq({})
    end

    it "parses enabled, scalar leaves, and headers.<name> (dotted name preserved), ignoring unknown leaves" do
      env = described_class.from_flat(
        "enabled" => true,
        "url" => "https://prod-override",
        :"headers.X-Foo.Bar" => "dotted",
        "method" => "PUT",
        "schedule" => "0 * * * *" # unknown to forwarders -> ignored
      )
      expect(env.enabled).to be(true)
      expect(env.url).to eq("https://prod-override")
      expect(env.method).to eq("PUT")
      expect(env.get_header("X-Foo.Bar")).to eq("dotted")
    end

    it "reads an un-overridden leaf as nil (pure override, no base merge)" do
      env = described_class.from_flat("enabled" => true)
      expect(env.url).to be_nil
      expect(env.success_status).to be_nil
    end
  end

  describe "header keys" do
    it "stringifies header keys passed to the constructor so get_header works by name" do
      env = described_class.new(headers: { "X-Foo": "v" })
      expect(env.get_header("X-Foo")).to eq("v")
      expect(env.to_payload["headers.X-Foo"]).to eq("v")
    end
  end
end
