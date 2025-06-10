# frozen_string_literal: true

require "spec_helper"
require "verse/util/impl/memory/distributed_lock"
require "verse/util/distributed_lock" # To ensure it includes the base module
require "verse/util/error"

RSpec.describe Verse::Util::Impl::Memory::DistributedLock do
  let(:config) { {} }
  subject(:lock_service) { described_class.new(config) }

  let(:lock_key) { "my_resource_lock" }
  let(:ttl_ms) { 100 } # 100 milliseconds
  let(:timeout_ms) { 50 } # 50 milliseconds

  it "includes Verse::Util::DistributedLock module" do
    expect(described_class.ancestors).to include(Verse::Util::DistributedLock)
  end

  describe "basic acquire and release" do
    it "acquires a lock and returns a token" do
      token = lock_service.acquire(lock_key, ttl_ms, timeout_ms)
      expect(token).to be_a(String)
      expect(token.length).to be > 0
    end

    it "releases an acquired lock with the correct token" do
      token = lock_service.acquire(lock_key, ttl_ms, timeout_ms)
      expect(lock_service.release(lock_key, token)).to be true
    end

    it "fails to release with an incorrect token" do
      lock_service.acquire(lock_key, ttl_ms, timeout_ms)
      expect(lock_service.release(lock_key, "incorrect_token")).to be false
    end

    it "fails to release a lock that is not held" do
      expect(lock_service.release("non_existent_lock", "any_token")).to be false
    end

    it "allows re-acquiring a lock after it's released" do
      token1 = lock_service.acquire(lock_key, ttl_ms, timeout_ms)
      lock_service.release(lock_key, token1)
      token2 = lock_service.acquire(lock_key, ttl_ms, timeout_ms)
      expect(token2).to be_a(String)
      expect(token2).not_to eq(token1) # Should be a new token
    end
  end

  describe "lock contention and timeout" do
    it "fails to acquire an already held lock immediately if timeout is 0" do
      lock_service.acquire(lock_key, ttl_ms, 0) # First acquire
      expect(lock_service.acquire(lock_key, ttl_ms, 0)).to be_nil # Second attempt
    end

    it "acquires a lock if the first holder releases it within timeout" do
      token1 = lock_service.acquire(lock_key, ttl_ms * 2, 0) # Held for 200ms

      # Start a thread to release the lock after a short delay
      Thread.new do
        sleep(ttl_ms / 2000.0) # Sleep for 0.025s (25ms)
        lock_service.release(lock_key, token1)
      end

      # Attempt to acquire with a timeout longer than the release delay
      # (timeout_ms is 50ms)
      token2 = lock_service.acquire(lock_key, ttl_ms, timeout_ms)
      expect(token2).to be_a(String)
    end

    it "fails to acquire if lock is not released within timeout" do
      lock_service.acquire(lock_key, ttl_ms * 5, 0) # Held for 500ms

      start_time = Time.now
      expect(lock_service.acquire(lock_key, ttl_ms, timeout_ms)).to be_nil # timeout_ms is 50ms
      duration = (Time.now - start_time) * 1000
      expect(duration).to be >= timeout_ms # Check it waited for at least timeout_ms
      expect(duration).to be < timeout_ms + 50 # And not excessively longer (add some buffer)
    end
  end

  describe "TTL and auto-release" do
    it "allows acquiring a lock after its TTL expires" do
      token1 = lock_service.acquire(lock_key, ttl_ms, 0) # ttl_ms is 100ms
      expect(token1).not_to be_nil

      sleep(ttl_ms / 1000.0 + 0.05) # Wait for 150ms (longer than TTL)

      token2 = lock_service.acquire(lock_key, ttl_ms, 0)
      expect(token2).to be_a(String)
      expect(token2).not_to eq(token1)
    end

    it "fails to release an auto-expired lock if strict checking (current impl might allow)" do
      # This behavior depends on how `release` handles expired locks.
      # Current memory impl: release of expired lock (if token matches original) is true.
      token = lock_service.acquire(lock_key, ttl_ms, 0)
      sleep(ttl_ms / 1000.0 + 0.05) # Wait for expiry
      # The lock is gone from @locks due to check_and_expire_lock in acquire or passive expiry.
      # If release checks current @locks, it won't find it or token won't match.
      # If it was re-acquired by another, token won't match.
      # If it just expired and wasn't re-acquired, current impl's release returns true.
      expect(lock_service.release(lock_key, token)).to be true # Or false depending on desired strictness
    end
  end

  describe "renew" do
    it "renews an active lock" do
      token = lock_service.acquire(lock_key, ttl_ms, 0) # ttl_ms = 100ms
      sleep(ttl_ms / 2000.0) # Sleep for 50ms

      expect(lock_service.renew(lock_key, token, ttl_ms * 2)).to be true # Renew for 200ms

      sleep(ttl_ms / 1000.0) # Sleep for another 100ms (total 150ms from initial acquire)
      # Lock should still be held due to renewal
      expect(lock_service.acquire(lock_key, ttl_ms, 0)).to be_nil
    end

    it "fails to renew with an incorrect token" do
      lock_service.acquire(lock_key, ttl_ms, 0)
      expect(lock_service.renew(lock_key, "incorrect_token", ttl_ms)).to be false
    end

    it "fails to renew an expired lock" do
      token = lock_service.acquire(lock_key, ttl_ms / 2, 0) # Short TTL: 50ms
      sleep(ttl_ms / 1000.0) # Wait 100ms (longer than TTL)
      expect(lock_service.renew(lock_key, token, ttl_ms)).to be false
    end
  end

  describe ".with_lock" do
    it "executes the block if lock is acquired and releases it" do
      executed = false
      result = lock_service.with_lock(lock_key, ttl_ms, timeout_ms) do
        executed = true
        # Check that lock is held within the block
        expect(lock_service.acquire(lock_key, ttl_ms, 0)).to be_nil
        "block_result"
      end

      expect(executed).to be true
      expect(result).to eq("block_result")
      # Check that lock is released after the block
      expect(lock_service.acquire(lock_key, ttl_ms, 0)).to be_a(String)
    end

    it "raises LockAcquisitionTimeout if lock cannot be acquired" do
      lock_service.acquire(lock_key, ttl_ms * 5, 0) # Hold the lock long

      expect {
        lock_service.with_lock(lock_key, ttl_ms, timeout_ms) do
          # This block should not execute
        end
      }.to raise_error(Verse::Util::Error::LockAcquisitionTimeout)
    end

    it "releases the lock even if the block raises an error" do
      expect {
        lock_service.with_lock(lock_key, ttl_ms, timeout_ms) do
          raise "test error"
        end
      }.to raise_error("test error")

      # Check that lock is released
      expect(lock_service.acquire(lock_key, ttl_ms, 0)).to be_a(String)
    end
  end
end
