# frozen_string_literal: true

module Verse
  module Util
    module Cache
      extend self

      attr_accessor :adapter, :enabled, :serializer

      # Set default adapter and serializer
      @adapter = Impl::Memory::CacheAdapter.new
      @serializer = Impl::Memory::ZMarshalSerializer.new

      @enabled = true

      # fetch the cache, or set it if it doesn't exist.
      # Every cache key are in the shape of [key]:[selector], where selector is a unique identifier for the cache and
      # key is the general identifier for the cache.
      # Example:
      #
      # with_cache("my_cache", "my_selector") do
      #  "my value"
      # end
      #
      # Cache is using ruby Marshal to serialize the data, so it can store any kind of data, as long as the
      # application reading it can deserialize it.
      #
      # If the data cannot be deserialized, it will ignore the cache and fetch the data again, then
      # store it in the cache (again).
      #
      # @param key [String] the key to fetch. Key acts as a general category of cache, and can be used to flush all cache
      # @param selector [String] the selector to fetch. Selector is a unique identifier for the cache,
      #                          and can be used to flush a specific cache
      # @param expires_in [Integer] the time in seconds before the cache key expires
      # @param block [Proc] the block to call if the cache is not found
      # @return [Object] the data fetched from the cache
      def with_cache(key, selector = "$nosel", expires_in: nil, &block)
        return block.call unless @enabled

        cached_data = adapter.fetch(key, selector)

        return load_payload(cached_data) if cached_data

        data = block.call

        adapter.cache(
          key,
          selector,
          build_payload(data),
          ex: expires_in
        )

        data
      end

      def build_payload(payload)
        @serializer.serialize(
          payload
        )
      end

      def load_payload(payload)
        return nil if payload.nil? || payload.empty?

        begin
          @serializer.deserialize(payload)
        rescue Verse::Errors::SerializationError => e
          Verse.logger.warn("Cache deserialization failed: #{e.message}")
          nil
        end
      end

      # flush the cache
      # @param key [String] the key to flush
      # @param selector [String, Array<String>] the selectors to flush.
      # If none is given, all the selectors for the key will be flushed.
      def flush(key, selectors = ["*"])
        selectors = [selectors] unless selectors.is_a?(Array)
        adapter.flush(key, selectors)
      end
    end
  end
end