# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::Debug do
  let(:original_enabled) { described_class.enabled? }

  after { described_class.enabled = original_enabled }

  it "is a no-op when disabled" do
    described_class.enabled = false
    expect { Smplkit.debug("x", "hi") }.not_to output.to_stderr
  end

  it "writes to stderr when enabled" do
    described_class.enabled = true
    expect { Smplkit.debug("x", "hi") }.to output(/\[smplkit:x\] .* hi/).to_stderr
  end

  it "Smplkit.enable_debug toggles the flag" do
    described_class.enabled = false
    Smplkit.enable_debug
    expect(described_class.enabled?).to be(true)
  end
end
