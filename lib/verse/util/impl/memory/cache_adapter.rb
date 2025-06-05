# frozen_string_literal: true

module Verse
  module Util
    module Impl
      module Memory
        class CacheAdapter
          def initialize
            @store = {} # Stores { cache_key => { value: data, expires_at: timestamp_or_nil } }
            @mutex = Mutex.new # For thread-safety
          end

          def fetch(key, selector)
            cache_key = "#{key}:#{selector}"

            @mutex.synchronize do
              entry = @store[cache_key]
              return nil unless entry

              expiration_time = entry[:expires_at]

              if expiration_time && Time.now.to_i >= expiration_time
                @store.delete(cache_key)
                return nil
              end

              entry[:value]
            end
          end

          def cache(key, selector, data, ex: nil)
            cache_key = "#{key}:#{selector}"

            @mutex.synchronize do
              expiration_time = ex ? (Time.now.to_i + ex) : nil
              @store[cache_key] = { value: data, expires_at: expiration_time }
            end

            data # Return the cached data
          end

          def flush(key, selectors)
            @mutex.synchronize do
              selectors_to_flush = selectors.is_a?(Array) ? selectors : [selectors]

              selectors_to_flush.each do |selector|
                if selector == "*"
                  # Flush all entries for the given key
                  prefix_to_clear = "#{key}:"
                  @store.keys.each do |k|
                    if k.start_with?(prefix_to_clear)
                      @store.delete(k)
                    end
                  end
                else
                  # Flush specific entry
                  cache_key_to_clear = "#{key}:#{selector}"
                  @store.delete(cache_key_to_clear)
                end
              end
            end
          end
        end
      end
    end
  end
end
