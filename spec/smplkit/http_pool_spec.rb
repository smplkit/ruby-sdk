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

  describe "wiring into the management plane" do
    subject(:mgmt) { Smplkit::ManagementClient.from_resolved(resolved) }

    let(:resolved) do
      Smplkit::ConfigResolution::ResolvedManagementConfig.new(
        api_key: "k", base_domain: "smplkit.test", scheme: "https", debug: false
      )
    end

    it "configures every generated service client to use the pooled adapter" do
      %i[_app_http _config_http _flags_http _logging_http _audit_http _jobs_http].each do |svc|
        adapter = built_adapter_for(mgmt.public_send(svc).config)
        expect(adapter).to eq(Faraday::Adapter::NetHttpPersistent),
                           "expected #{svc} to use NetHttpPersistent, got #{adapter}"
      end
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
