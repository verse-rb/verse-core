# frozen_string_literal: true

require_relative "./error"

module Verse
  module Util
    # Abstract module defining the interface for a distributed lock.
    # Concrete implementations (e.g., in-memory, Redis-backed) should include
    # this module and implement its methods.
    module DistributedLock
      # Initializes the distributed lock adapter.
      #
      # @param config [Hash] Adapter-specific configuration.
      def initialize(config = {}); end

      # Attempts to acquire a lock.
      #
      # @param lock_key [String] A unique key identifying the lock.
      # @param requested_ttl_ms [Integer] The requested time-to-live for the lock in milliseconds.
      #        The lock should auto-release after this duration if not explicitly released or renewed.
      # @param acquire_timeout_ms [Integer] The maximum time in milliseconds to wait to acquire the lock.
      #        If 0, it attempts to acquire the lock once and returns immediately.
      # @return [String, nil] A unique lock token if the lock was acquired, or nil if the acquisition timed out
      #         or failed. This token must be used for releasing or renewing the lock.
      # @raise [Verse::Util::Error::LockError] for unexpected errors during acquisition.
      def acquire(lock_key, requested_ttl_ms, acquire_timeout_ms) = raise NotImplementedError

      # Releases a previously acquired lock.
      #
      # @param lock_key [String] The key of the lock to release.
      # @param lock_token [String] The token received when the lock was acquired.
      #        This ensures that only the holder of the lock can release it.
      # @return [Boolean] True if the lock was successfully released, false otherwise (e.g., token mismatch, lock not found).
      # @raise [Verse::Util::Error::LockReleaseError] for critical errors during release.
      def release(lock_key, lock_token) = raise NotImplementedError

      # Renews/extends the TTL of an acquired lock.
      #
      # @param lock_key [String] The key of the lock to renew.
      # @param lock_token [String] The token received when the lock was acquired.
      # @param new_ttl_ms [Integer] The new time-to-live for the lock in milliseconds, from the moment of renewal.
      # @return [Boolean] True if the lock TTL was successfully renewed, false otherwise (e.g., token mismatch, lock expired).
      # @raise [Verse::Util::Error::LockRenewalError] for critical errors during renewal.
      def renew(lock_key, lock_token, new_ttl_ms)= raise NotImplementedError

      # A convenience method to acquire a lock, execute a block of code,
      # and ensure the lock is released.
      #
      # @param lock_key [String] The lock key.
      # @param requested_ttl_ms [Integer] Lock TTL.
      # @param acquire_timeout_ms [Integer] Timeout for acquiring the lock.
      # @yield If the lock is acquired, the block is executed.
      # @return The result of the block if the lock was acquired and the block executed.
      # @raise [Verse::Util::Error::LockAcquisitionTimeoutError] if the lock cannot be acquired within the timeout.
      # @raise [StandardError] any error raised within the block.
      def with_lock(lock_key, requested_ttl_ms, acquire_timeout_ms)
        token = acquire(lock_key, requested_ttl_ms, acquire_timeout_ms)

        unless token
          raise Error::LockAcquisitionTimeout, "Failed to acquire lock '#{lock_key}' within #{acquire_timeout_ms}ms."
        end

        begin
          yield
        ensure
          release(lock_key, token)
        end
      end
    end
  end
end
