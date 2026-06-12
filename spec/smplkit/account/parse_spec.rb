# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Account::SettingsClient do
  subject(:account) { Smplkit::Account::AccountClient.new(api_key: "k", base_url: base_url) }

  let(:base_url) { "https://app.smplkit.test" }
  let(:path) { "#{base_url}/api/v1/accounts/current/settings" }

  it "falls back to an empty hash when the body is not valid JSON" do
    stub_request(:get, path).to_return(status: 200, body: "not json{")
    expect(account.settings.get.raw).to eq({})
  end
end
