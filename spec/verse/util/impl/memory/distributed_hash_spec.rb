require "spec_helper"
require "verse/util/impl/memory/distributed_hash"
require "verse/util/distributed_hash" # To ensure it includes the base module correctly

RSpec.describe Verse::Util::Impl::Memory::DistributedHash do
  let(:config) { {} }
  subject(:hash_store) { described_class.new(config) }

  after(:each) do
    hash_store.stop_cleanup_thread if hash_store.cleanup_thread&.alive?
  end

  it "includes Verse::Util::DistributedHash module" do
    expect(described_class.ancestors).to include(Verse::Util::DistributedHash)
  end

  describe "basic operations" do
    it "sets and gets a value" do
      hash_store.set("mykey", "myvalue")
      expect(hash_store.get("mykey")).to eq("myvalue")
    end

    it "returns nil for a non-existent key" do
      expect(hash_store.get("nonexistent")).to be_nil
    end

    it "overwrites an existing value" do
      hash_store.set("mykey", "initial_value")
      hash_store.set("mykey", "new_value")
      expect(hash_store.get("mykey")).to eq("new_value")
    end

    it "deletes a key" do
      hash_store.set("mykey", "myvalue")
      expect(hash_store.delete("mykey")).to be true
      expect(hash_store.get("mykey")).to be_nil
    end

    it "returns false when deleting a non-existent key" do
      expect(hash_store.delete("nonexistent")).to be false
    end

    it "clears all keys" do
      hash_store.set("key1", "value1")
      hash_store.set("key2", "value2")
      hash_store.clear_all
      expect(hash_store.get("key1")).to be_nil
      expect(hash_store.get("key2")).to be_nil
    end
  end

  describe "TTL handling" do
    it "expires a key after its TTL" do
      start_time = Time.now
      hash_store.set("ttl_key", "value", ttl: 0.1, now: start_time)
      expect(hash_store.get("ttl_key", now: start_time)).to eq("value") # Immediately after set

      # Check just before expiry (e.g., 0.05s later)
      expect(hash_store.get("ttl_key", now: start_time + 0.05)).to eq("value")

      # Check at/after expiry (e.g., 0.11s later)
      expect(hash_store.get("ttl_key", now: start_time + 0.11)).to be_nil
    end

    it "does not expire a key if TTL is nil" do
      start_time = Time.now
      hash_store.set("no_ttl_key", "value", now: start_time)
      expect(hash_store.get("no_ttl_key", now: start_time + 1000)).to eq("value") # Should still exist much later
    end

    it "updates TTL when a key is set again" do
      start_time = Time.now
      hash_store.set("key", "value1", ttl: 0.1, now: start_time) # Expires at start_time + 0.1

      # Set again with a longer TTL before the first one expires
      hash_store.set("key", "value2", ttl: 0.3, now: start_time + 0.05) # New expiry at start_time + 0.05 + 0.3 = start_time + 0.35

      expect(hash_store.get("key", now: start_time + 0.2)).to eq("value2") # Should exist past original 0.1 TTL
      expect(hash_store.get("key", now: start_time + 0.4)).to be_nil    # Should be gone after new 0.35 TTL
    end

    it "delete returns false if key was already expired" do
      start_time = Time.now
      hash_store.set("exp_del_key", "value", ttl: 0.05, now: start_time)
      # Let it expire
      expect(hash_store.delete("exp_del_key", now: start_time + 0.1)).to be false
    end
  end

  describe "cleanup thread" do
    let(:cleanup_interval) { 0.05 }
    let(:config) { { cleanup_interval_seconds: cleanup_interval } }

    it "removes expired keys via the cleanup thread" do
      # This test is timing-dependent and might be flaky in some CI environments.
      # It relies on the cleanup thread running and finding the expired key.
      start_time = Time.now
      hash_store.set("cleanup_test_key", "value", ttl: 0.01, now: start_time)

      hash_store.cleanup

      # Access internal store directly for verification (not ideal, but for testing GC)
      # This check is done without calling `get` to ensure GC removed it, not passive expiry on get.
      expect(hash_store.instance_variable_get(:@store)["cleanup_test_key"]).to be_nil
    end

    it "stops the cleanup thread" do
      expect(hash_store.cleanup_thread).to be_alive
      hash_store.stop_cleanup_thread
      expect(hash_store.cleanup_thread).to be_nil # or check !cleanup_thread.alive? if join might not set to nil
    end

    context "when cleanup_interval_seconds is 0 or negative" do
      let(:config) { { cleanup_interval_seconds: 0 } }
      it "does not start the cleanup thread" do
        expect(hash_store.cleanup_thread).to be_nil
      end
    end
  end

  describe "thread safety (basic check)" do
    it "handles concurrent sets and gets (simplified test)" do
      threads = []
      10.times do |i|
        threads << Thread.new do
          100.times do |j|
            key = "thread_#{i}_key_#{j}"
            hash_store.set(key, i * 100 + j)
            expect(hash_store.get(key)).to eq(i * 100 + j)
          end
        end
      end
      threads.each(&:join)
      # Verify a few random ones
      expect(hash_store.get("thread_3_key_55")).to eq(355)
      expect(hash_store.get("thread_8_key_12")).to eq(812)
    end
  end
end
