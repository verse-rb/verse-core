# frozen_string_literal: true

require "spec_helper"
require "verse/cache/cache"

RSpec.describe Verse::Cache do
  let(:adapter) { Verse::Cache::Impl::MemoryCacheAdapter.new }
  let(:serializer) { Verse::Cache::Impl::ZMarshalSerializer.new }

  before do
    described_class.adapter = adapter
    described_class.serializer = serializer
    described_class.enabled = true
  end

  describe ".with_cache" do
    it "caches the result of the block" do
      expect(adapter).to receive(:cache).with("key", "selector", serializer.serialize("data"), ex: nil).and_call_original
      expect(
        described_class.with_cache("key", "selector") { "data" }
      ).to eq("data")
    end

    it "returns the cached value if it exists" do
      adapter.cache("key", "selector", serializer.serialize("data"))
      expect(adapter).not_to receive(:cache)
      expect(
        described_class.with_cache("key", "selector") { "new_data" }
      ).to eq("data")
    end

    it "recaches if deserialization fails" do
      adapter.cache("key", "selector", "invalid_data")
      expect(adapter).to receive(:cache).with("key", "selector", serializer.serialize("new_data"), ex: nil).and_call_original
      expect(
        described_class.with_cache("key", "selector") { "new_data" }
      ).to eq("new_data")
    end

    it "respects the expires_in option" do
      now = Time.now
      allow(Time).to receive(:now).and_return(now)

      described_class.with_cache("key", "selector", expires_in: 1) { "data" }

      allow(Time).to receive(:now).and_return(now + 1.1)
      expect(
        described_class.with_cache("key", "selector") { "new_data" }
      ).to eq("new_data")
    end

    it "does not cache if disabled" do
      described_class.enabled = false
      expect(adapter).not_to receive(:cache)
      expect(
        described_class.with_cache("key", "selector") { "data" }
      ).to eq("data")
    end
  end

  describe ".flush" do
    it "flushes the cache" do
      adapter.cache("key", "selector", serializer.serialize("data"))
      described_class.flush("key", "selector")
      expect(adapter.fetch("key", "selector")).to be_nil
    end

    it "flushes all selectors for a key with a wildcard" do
      adapter.cache("key", "selector1", serializer.serialize("data1"))
      adapter.cache("key", "selector2", serializer.serialize("data2"))
      described_class.flush("key", "*")
      expect(adapter.fetch("key", "selector1")).to be_nil
      expect(adapter.fetch("key", "selector2")).to be_nil
    end
  end
end
