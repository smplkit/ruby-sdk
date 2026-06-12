# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::ApiSupport::ErrorMapping do
  describe ".call" do
    it "re-raises the original ApiError when the generated layer raised on a 2xx code" do
      # raise_for_status only returns on a 2xx status; if the generated layer
      # raised an ApiError carrying a 2xx code (which it never should), the
      # mapper falls through to its defensive `raise` and re-raises the
      # original error unchanged.
      original = SmplkitGeneratedClient::Audit::ApiError.new(code: 200, response_body: "")
      expect do
        described_class.call { raise original }
      end.to raise_error(SmplkitGeneratedClient::Audit::ApiError) do |raised|
        expect(raised).to be(original)
        expect(raised.code).to eq(200)
      end
    end
  end
end
