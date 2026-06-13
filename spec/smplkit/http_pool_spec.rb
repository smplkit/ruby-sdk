# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::HttpPool do
  # Rebuild a Faraday connection the way the generated
  # +ApiClient#build_connection+ does: set the default adapter first, then
  # replay the +configure_faraday_connection+ blocks. The adapter the
  # connection ends up with is what every request will use.
  def built_adapter_for(configuration)
    conn = Faraday.new(url: "https://example.com") do |c|
      c.adapter(Faraday.default_adapter)
      configuration.configure_connection(c)
    end
    conn.builder.adapter.klass
  end

  describe ".configure" do
    let(:configuration) { SmplkitGeneratedClient::Flags::Configuration.new }

    it "overrides the default net/http adapter with the keepalive pool" do
      expect(Faraday.default_adapter).to eq(:net_http) # guard: this is what we replace
      described_class.configure(configuration)
      expect(built_adapter_for(configuration)).to eq(Faraday::Adapter::NetHttpPersistent)
    end

    it "returns the configuration for chaining" do
      expect(described_class.configure(configuration)).to be(configuration)
    end
  end

  describe "wiring through Transport.build_api_client" do
    let(:resolved) do
      Smplkit::ConfigResolution::ResolvedClientConfig.new(
        api_key: "k", base_domain: "smplkit.test", scheme: "https", debug: false
      )
    end

    # Every per-service transport is built via +Transport.build_api_client+,
    # which calls +HttpPool.configure+ on the generated +Configuration+ before
    # constructing the client. Assert each ends up with the keepalive adapter.
    {
      app: SmplkitGeneratedClient::App,
      config: SmplkitGeneratedClient::Config,
      flags: SmplkitGeneratedClient::Flags,
      logging: SmplkitGeneratedClient::Logging,
      jobs: SmplkitGeneratedClient::Jobs
    }.each do |subdomain, generated_module|
      it "configures the #{subdomain} client to use the pooled adapter" do
        client = Smplkit::Transport.build_api_client(generated_module, subdomain.to_s, resolved)
        adapter = built_adapter_for(client.config)
        expect(adapter).to eq(Faraday::Adapter::NetHttpPersistent),
                           "expected #{subdomain} to use NetHttpPersistent, got #{adapter}"
      end
    end

    it "configures the Configuration directly when called on its own" do
      configuration = SmplkitGeneratedClient::Logging::Configuration.new
      described_class.configure(configuration)
      expect(built_adapter_for(configuration)).to eq(Faraday::Adapter::NetHttpPersistent)
    end

    it "is invoked by build_api_client for every constructed transport" do
      allow(described_class).to receive(:configure).and_call_original
      Smplkit::Transport.build_api_client(SmplkitGeneratedClient::Logging, "logging", resolved)
      expect(described_class).to have_received(:configure)
        .with(an_instance_of(SmplkitGeneratedClient::Logging::Configuration))
    end
  end

  describe "wiring into the standalone audit client" do
    it "configures the audit Configuration with the pooled adapter" do
      allow(described_class).to receive(:configure).and_call_original
      Smplkit::Audit::AuditClient.new(api_key: "k", base_url: "https://audit.example.com")
      expect(described_class).to have_received(:configure)
        .with(an_instance_of(SmplkitGeneratedClient::Audit::Configuration))
    end
  end
end
