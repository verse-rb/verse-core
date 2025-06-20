# frozen_string_literal: true

module Verse
  module Distributed
    # Abstract module defining the interface for a simple distributed key-value store.
    # Concrete implementations (e.g., in-memory, Redis-backed) should include
    # this module and implement its methods.
    module KVStore
      attr_reader :config

      # Initializes the distributed hash adapter.
      #
      # @param config [Hash] Adapter-specific configuration.
      def initialize(config = {})
        @config = config
      end

      # Retrieves the value associated with a key.
      #
      # @param key [String] The key whose value is to be retrieved.
      # @return [Object, nil] The value associated with the key, or nil if the key is not found or expired.
      def get(key)= raise NotImplementedError # :nocov:

      # Sets a key-value pair.
      #
      # @param key [String] The key to set.
      # @param value [Object] The value to associate with the key.
      # @param ttl [Integer, nil] Time-to-live for the key-value pair in seconds.
      #        If nil, the pair persists indefinitely (or as per backend default).
      # @return [void]
      def set(key, value, ttl: nil)= raise NotImplementedError # :nocov:

      # Deletes a key-value pair.
      #
      # @param key [String] The key to delete.
      # @return [Boolean] True if the key was deleted, false if it was not found.
      def delete(key)= raise NotImplementedError # :nocov:

      # Clears all key-value pairs from the store.
      # Use with caution.
      #
      # @return [void]
      def clear_all()= raise NotImplementedError # :nocov:
    end
  end
end
