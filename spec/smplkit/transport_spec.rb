# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Transport do
  let(:resolved) do
    Smplkit::ConfigResolution::ResolvedClientConfig.new(
      api_key: "k", base_domain: "smplkit.test", scheme: "https", debug: false
    )
  end

  describe ".to_transport_config" do
    it "projects a runtime ResolvedConfig down to the transport subset" do
      runtime = Smplkit::ConfigResolution::ResolvedConfig.new(
        api_key: "k", base_domain: "smplkit.test", scheme: "https",
        environment: "prod", service: "svc", debug: true, telemetry: false
      )
      cfg = described_class.to_transport_config(runtime)
      expect(cfg).to be_a(Smplkit::ConfigResolution::ResolvedClientConfig)
      expect(cfg.api_key).to eq("k")
      expect(cfg.base_domain).to eq("smplkit.test")
      expect(cfg.scheme).to eq("https")
      expect(cfg.debug).to be(true)
      expect(cfg.extra_headers).to be_nil
    end

    it "carries extra_headers through when supplied" do
      runtime = Smplkit::ConfigResolution::ResolvedConfig.new(
        api_key: "k", base_domain: "smplkit.test", scheme: "https",
        environment: nil, service: nil, debug: false, telemetry: true
      )
      cfg = described_class.to_transport_config(runtime, { "X-Custom" => "v" })
      expect(cfg.extra_headers).to eq("X-Custom" => "v")
    end
  end

  describe Smplkit::Transport::ServiceTransports do
    it "is a keyword-init struct whose close is a harmless no-op" do
      transports = described_class.new(app_url: "https://app.smplkit.test", api_key: "k")
      expect(transports.app_url).to eq("https://app.smplkit.test")
      expect(transports.api_key).to eq("k")
      expect { transports.close }.not_to raise_error
      expect(transports.close).to be_nil
    end
  end

  describe ".build_service_transports" do
    subject(:transports) { described_class.build_service_transports(resolved) }

    it "carries the app_url and api_key alongside the per-service transports" do
      expect(transports.app_url).to eq("https://app.smplkit.test")
      expect(transports.api_key).to eq("k")
    end

    it "builds one transport per backend service pointed at its subdomain" do
      expect(transports.app_http.config.host).to eq("app.smplkit.test")
      expect(transports.config_http.config.host).to eq("config.smplkit.test")
      expect(transports.flags_http.config.host).to eq("flags.smplkit.test")
      expect(transports.logging_http.config.host).to eq("logging.smplkit.test")
      expect(transports.jobs_http.config.host).to eq("jobs.smplkit.test")
    end

    it "stamps the SDK User-Agent on every transport" do
      ua = "smplkit-ruby-sdk/#{Smplkit::VERSION}"
      expect(transports.app_http.default_headers["User-Agent"]).to eq(ua)
      expect(transports.jobs_http.default_headers["User-Agent"]).to eq(ua)
    end

    it "carries the JSON:API Accept header only on the jobs transport" do
      expect(transports.jobs_http.default_headers["Accept"]).to eq("application/vnd.api+json")
      expect(transports.app_http.default_headers["Accept"]).to be_nil
    end
  end

  describe ".build_api_client" do
    it "derives scheme and host from subdomain and base_domain" do
      client = described_class.build_api_client(SmplkitGeneratedClient::App, "app", resolved)
      expect(client.config.scheme).to eq("https")
      expect(client.config.host).to eq("app.smplkit.test")
      expect(client.config.base_path).to eq("")
      expect(client.config.access_token).to eq("k")
      expect(client.default_headers["User-Agent"]).to eq("smplkit-ruby-sdk/#{Smplkit::VERSION}")
    end

    it "applies the Accept header when one is passed" do
      client = described_class.build_api_client(
        SmplkitGeneratedClient::Jobs, "jobs", resolved, accept: "application/vnd.api+json"
      )
      expect(client.default_headers["Accept"]).to eq("application/vnd.api+json")
    end

    it "overrides scheme/host from base_url, stripping default ports" do
      client = described_class.build_api_client(
        SmplkitGeneratedClient::App, "app", resolved, base_url: "https://custom.example.com"
      )
      expect(client.config.scheme).to eq("https")
      expect(client.config.host).to eq("custom.example.com")
    end

    it "preserves a non-default port from base_url in the host" do
      client = described_class.build_api_client(
        SmplkitGeneratedClient::App, "app", resolved, base_url: "http://localhost:8000"
      )
      expect(client.config.scheme).to eq("http")
      expect(client.config.host).to eq("localhost:8000")
    end

    it "applies caller extra_headers but skips SDK-owned headers" do
      cfg = Smplkit::ConfigResolution::ResolvedClientConfig.new(
        api_key: "k", base_domain: "smplkit.test", scheme: "https", debug: false,
        extra_headers: {
          "X-Pass" => "yes",
          "Authorization" => "Bearer rogue",
          "User-Agent" => "rogue",
          "Content-Type" => "text/plain"
        }
      )
      client = described_class.build_api_client(SmplkitGeneratedClient::App, "app", cfg)
      expect(client.default_headers["X-Pass"]).to eq("yes")
      expect(client.default_headers["User-Agent"]).to eq("smplkit-ruby-sdk/#{Smplkit::VERSION}")
      expect(client.default_headers["Authorization"]).not_to eq("Bearer rogue")
      expect(client.default_headers["Content-Type"]).not_to eq("text/plain")
    end
  end
end
