# frozen_string_literal: true

require "spec_helper"
require "verse/cache/impl/memory_cache_adapter"

RSpec.describe Verse::Cache::Impl::MemoryCacheAdapter do
  let(:capacity) { 10 }
  let(:adapter) { described_class.new(capacity) }

  describe "#initialize" do
    it "initializes with a given capacity" do
      expect(adapter.instance_variable_get(:@capacity)).to eq(capacity)
    end
  end

  describe "#fetch and #cache" do
    it "caches and fetches data" do
      adapter.cache("key1", "selector1", "data1")
      expect(adapter.fetch("key1", "selector1")).to eq("data1")
    end

    it "returns nil for non-existent keys" do
      expect(adapter.fetch("key1", "selector1")).to be_nil
    end

    it "updates existing data" do
      adapter.cache("key1", "selector1", "data1")
      adapter.cache("key1", "selector1", "data2")
      expect(adapter.fetch("key1", "selector1")).to eq("data2")
    end

    it "updates the size of the cache" do
      expect(adapter.size).to eq(0)
      adapter.cache("key1", "selector1", "data1")
      expect(adapter.size).to eq(1)
      adapter.cache("key1", "selector2", "data2")
      expect(adapter.size).to eq(2)
      adapter.remove("key1", "selector1")
      expect(adapter.size).to eq(1)
    end

    it "handles expiration" do
      now = Time.now
      allow(Time).to receive(:now).and_return(now)

      adapter.cache("key1", "selector1", "data1", ex: 1)

      allow(Time).to receive(:now).and_return(now + 1.1)
      expect(adapter.fetch("key1", "selector1")).to be_nil
    end
  end

  describe "LRU mechanism" do
    it "evicts the least recently used item when capacity is exceeded" do
      (1..capacity).each { |i| adapter.cache("key#{i}", "selector", "data#{i}") }
      # Access key1 to make it recently used
      adapter.fetch("key1", "selector")
      # Add one more item to exceed capacity
      adapter.cache("key#{capacity + 1}", "selector", "data#{capacity + 1}")

      # key2 should be evicted as it was the least recently used
      expect(adapter.fetch("key2", "selector")).to be_nil
      expect(adapter.fetch("key1", "selector")).to eq("data1")
    end
  end

  describe "#remove" do
    it "removes a specific item from the cache" do
      adapter.cache("key1", "selector1", "data1")
      adapter.remove("key1", "selector1")
      expect(adapter.fetch("key1", "selector1")).to be_nil
    end
  end

  describe "#flush" do
    before do
      adapter.cache("key1", "selector1", "data1")
      adapter.cache("key1", "selector2", "data2")
      adapter.cache("key2", "selector1", "data3")
    end

    it "flushes a single selector" do
      adapter.flush("key1", "selector1")
      expect(adapter.fetch("key1", "selector1")).to be_nil
      expect(adapter.fetch("key1", "selector2")).to eq("data2")
    end

    it "flushes multiple selectors" do
      adapter.flush("key1", ["selector1", "selector2"])
      expect(adapter.fetch("key1", "selector1")).to be_nil
      expect(adapter.fetch("key1", "selector2")).to be_nil
    end

    it "flushes all selectors for a key with a wildcard" do
      adapter.flush("key1", "*")
      expect(adapter.fetch("key1", "selector1")).to be_nil
      expect(adapter.fetch("key1", "selector2")).to be_nil
      expect(adapter.fetch("key2", "selector1")).to eq("data3")
    end
  end
end
