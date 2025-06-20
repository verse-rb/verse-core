# frozen_string_literal: true

require_relative "impl/memory_cache_adapter"
require_relative "impl/z_marshal_serializer"

module Verse
  module Cache
    SerializationError = Class.new(Verse::Error::Base)

    extend self

    attr_accessor :adapter, :enabled, :serializer

    @enabled = true

    def setup!
      return if @setup_done || !@enabled

      config = Verse.config.cache

      adapter_klass = Verse::Util::Reflection.constantize(config.adapter)
      serializer_klass = Verse::Util::Reflection.constantize(config.serializer)

      @adapter = adapter_klass.new(**config.config)
      @serializer = serializer_klass.new
      @setup_done = true
    end

    # fetch the cache, or set it if it doesn't exist.
    # Every cache key are in the shape of [key]:[selector], where selector is a unique identifier for the cache and
    # key is theattiribute general identifier for the cache.
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
      setup!
      return block.call unless @enabled

      cached_data = adapter.fetch(key, selector)

      data = load_payload(cached_data) if cached_data

      return data if data

      data = block.call

      adapter.cache(
        key,
        selector,
        build_payload(data),
        ex: expires_in
      )

      data
    end

    # Allow to Call Verse::Cache[:key, :selector] do ... end
    def [](key, selector = "$nosel", expires_in: nil, &block)
      with_cache(key, selector, expires_in: expires_in, &block)
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
      rescue Verse::Cache::SerializationError => e
        Verse.logger&.warn("Cache deserialization failed: #{e.message}")
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
