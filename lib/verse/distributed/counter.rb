# frozen_string_literal: true

module Verse
  module Distributed
    # Abstract module defining the interface for a distributed atomic counter.
    # Concrete implementations (e.g., in-memory, Redis-backed) should include
    # this module and implement its methods.
    module Counter

      attr_reader :config

      # Initializes the distributed counter adapter.
      #
      # @param config [Hash] Adapter-specific configuration.
      def initialize(config = {})
        @config = config
      end

      # Atomically increments the value of the counter by a given amount.
      # If the counter does not exist, it is initialized to 0 before performing the operation.
      #
      # @param counter_name [String] The name of the counter.
      # @param amount [Integer] The amount to increment by (default is 1). Can be negative to decrement.
      # @param ttl [Integer, nil] Time-to-live for the counter in seconds.
      #        If set, the counter will expire after this duration.
      #        The behavior of TTL (e.g., reset on each increment) may vary by backend.
      # @return [Integer] The new value of the counter after incrementing.
      # :nocov:
      def increment(counter_name, amount = 1, ttl: nil) = raise NotImplementedError
      # :nocov:

      # Atomically decrements the value of the counter by a given amount.
      # This is often a convenience method for `increment(key, -amount, ttl: ttl)`.
      #
      # @param counter_name [String] The name of the counter.
      # @param amount [Integer] The amount to decrement by (default is 1).
      # @param ttl [Integer, nil] Time-to-live for the counter in seconds.
      # @return [Integer] The new value of the counter after decrementing.
      def decrement(counter_name, amount = 1, ttl: nil)
        increment(counter_name, -amount, ttl: ttl)
      end

      # Retrieves the current value of the counter.
      #
      # @param counter_name [String] The name of the counter.
      # @return [Integer, nil] The current value of the counter, or nil if the counter does not exist.
      # :nocov:
      def get(counter_name) = raise NotImplementedError
      # :nocov:

      # Sets the value of the counter to a specific value.
      # This operation might not be atomic in all backends if combined with increments/decrements.
      #
      # @param counter_name [String] The name of the counter.
      # @param value [Integer] The value to set the counter to.
      # @param ttl [Integer, nil] Time-to-live for the counter in seconds.
      # @return [void]
      # :nocov:
      def set(counter_name, value, ttl: nil) = raise NotImplementedError
      # :nocov:

      # Deletes the counter.
      #
      # @param counter_name [String] The name of the counter to delete.
      # @return [Boolean] True if the counter was deleted, false if it did not exist.
      # :nocov:
      def delete(counter_name) = raise NotImplementedError
      # :nocov:

      # Checks if the counter exists.
      #
      # @param counter_name [String] The name of the counter.
      # @return [Boolean] True if the counter exists, false otherwise.
      # :nocov:
      def exists?(counter_name) = raise NotImplementedError
      # :nocov:
    end
  end
end
