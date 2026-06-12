# frozen_string_literal: true

require "spec_helper"
require "semantic_logger"
require "smplkit/logging/adapters/semantic_logger_adapter"

RSpec.describe Smplkit::Logging::Adapters::SemanticLoggerAdapter do
  subject(:adapter) { described_class.new }

  it "on_new_logger_created rescues errors raised by the on_new callback" do
    adapter.install_hook { |_n, _e, _l| raise "boom" }
    fake = double("SemanticLogger::Logger")
    allow(fake).to receive(:name).and_return("x")
    allow(fake).to receive(:respond_to?).with(:level).and_return(false)
    expect { adapter.send(:on_new_logger_created, fake) }.not_to raise_error
  ensure
    adapter.uninstall_hook
  end

  describe ".reset_hook!" do
    it "clears the per-class hook module" do
      described_class.reset_hook!
      expect(described_class.send(:hook_installed?)).to be(false)
    end
  end
end
