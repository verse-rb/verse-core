# frozen_string_literal: true

require "spec_helper"
require "verse/util/impl/memory/distributed_counter"
require "verse/util/distributed_counter" # To ensure it includes the base module

RSpec.describe Verse::Util::Impl::Memory::DistributedCounter do
  let(:config) { {} } # In-memory counter might not need config, but for consistency
  subject(:counter_store) { described_class.new(config) }

  it "includes Verse::Util::DistributedCounter module" do
    expect(described_class.ancestors).to include(Verse::Util::DistributedCounter)
  end

  describe "basic operations" do
    it "increments a new counter" do
      expect(counter_store.increment("mycounter")).to eq(1)
      expect(counter_store.get("mycounter")).to eq(1)
    end

    it "increments an existing counter" do
      counter_store.set("mycounter", 5)
      expect(counter_store.increment("mycounter")).to eq(6)
    end

    it "increments by a specific amount" do
      counter_store.set("mycounter", 5)
      expect(counter_store.increment("mycounter", 3)).to eq(8)
    end

    it "decrements a counter" do
      counter_store.set("mycounter", 5)
      expect(counter_store.decrement("mycounter")).to eq(4)
      expect(counter_store.decrement("mycounter", 2)).to eq(2)
    end

    it "gets the value of a counter" do
      counter_store.set("mycounter", 101)
      expect(counter_store.get("mycounter")).to eq(101)
    end

    it "returns nil for a non-existent counter on get" do
      expect(counter_store.get("nonexistent")).to be_nil
    end

    it "sets a counter value" do
      counter_store.set("mycounter", 42)
      expect(counter_store.get("mycounter")).to eq(42)
    end

    it "deletes a counter" do
      counter_store.set("mycounter", 7)
      expect(counter_store.delete("mycounter")).to be true
      expect(counter_store.get("mycounter")).to be_nil
    end

    it "returns false when deleting a non-existent counter" do
      expect(counter_store.delete("nonexistent")).to be false
    end
  end

  describe "TTL handling" do
    let(:start_time) { Time.now }

    it "expires a counter after its TTL on increment" do
      counter_store.increment("ttl_counter", 1, ttl: 0.1, now: start_time)
      expect(counter_store.get("ttl_counter", now: start_time + 0.05)).to eq(1)
      expect(counter_store.get("ttl_counter", now: start_time + 0.11)).to be_nil
    end

    it "expires a counter after its TTL on set" do
      counter_store.set("ttl_set_counter", 10, ttl: 0.1, now: start_time)
      expect(counter_store.get("ttl_set_counter", now: start_time + 0.05)).to eq(10)
      expect(counter_store.get("ttl_set_counter", now: start_time + 0.11)).to be_nil
    end

    it "resets TTL on subsequent increment if ttl is provided" do
      counter_store.increment("counter", 1, ttl: 0.1, now: start_time) # Expires at start_time + 0.1
      # Increment again before expiry, with new TTL
      counter_store.increment("counter", 1, ttl: 0.2, now: start_time + 0.05) # New value 2, expires at start_time + 0.05 + 0.2 = start_time + 0.25

      expect(counter_store.get("counter", now: start_time + 0.15)).to eq(2) # Still exists past original 0.1 TTL
      expect(counter_store.get("counter", now: start_time + 0.30)).to be_nil # Expired after new TTL
    end

    it "persists TTL if not provided on subsequent increment" do
      # Set with TTL
      counter_store.increment("counter", 1, ttl: 0.1, now: start_time) # Expires at start_time + 0.1
      # Increment without new TTL
      counter_store.increment("counter", 1, now: start_time + 0.02) # Value 2, still expires at start_time + 0.1

      expect(counter_store.get("counter", now: start_time + 0.08)).to eq(2)
      expect(counter_store.get("counter", now: start_time + 0.12)).to be_nil
    end

    it "does not expire if TTL is nil" do
      counter_store.set("no_ttl_counter", 20, now: start_time)
      expect(counter_store.get("no_ttl_counter", now: start_time + 1000)).to eq(20)
    end
  end

  describe "thread safety (basic check)" do
    it "handles concurrent increments (simplified test)" do
      threads = []
      target_value = 1000
      counter_name = "concurrent_counter"

      target_value.times do
        threads << Thread.new do
          counter_store.increment(counter_name)
        end
      end
      threads.each(&:join)
      expect(counter_store.get(counter_name)).to eq(target_value)
    end
  end
end
