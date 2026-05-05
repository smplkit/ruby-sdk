# frozen_string_literal: true

require "spec_helper"

RSpec.describe Smplkit::RequestContext do
  let(:contexts) { [Smplkit::Context.new("user", "u-1")] }

  it "starts empty" do
    expect(described_class.get).to eq([])
  end

  it "set/reset preserves prior value" do
    prev = described_class.set(contexts)
    expect(described_class.get).to eq(contexts)
    described_class.reset(prev)
    expect(described_class.get).to eq([])
  end
end

RSpec.describe Smplkit::ContextScope do
  let(:contexts) { [Smplkit::Context.new("user", "u-1")] }

  it "exit restores prior context" do
    scope = Smplkit.set_request_context(contexts)
    expect(Smplkit.request_context).to eq(contexts)
    scope.exit
    expect(Smplkit.request_context).to eq([])
  end

  it "exit is idempotent" do
    scope = Smplkit.set_request_context(contexts)
    scope.exit
    expect { scope.exit }.not_to raise_error
  end

  it "block form auto-exits" do
    scope = Smplkit.set_request_context(contexts)
    scope.call { expect(Smplkit.request_context).to eq(contexts) }
    expect(Smplkit.request_context).to eq([])
  end

  it "nests properly" do
    outer = Smplkit.set_request_context([Smplkit::Context.new("user", "u-outer")])
    inner = Smplkit.set_request_context([Smplkit::Context.new("user", "u-inner")])
    expect(Smplkit.request_context.first.key).to eq("u-inner")
    inner.exit
    expect(Smplkit.request_context.first.key).to eq("u-outer")
    outer.exit
    expect(Smplkit.request_context).to eq([])
  end
end
