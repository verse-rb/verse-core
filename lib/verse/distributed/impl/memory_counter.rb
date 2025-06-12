# frozen_string_literal: true

require_relative "../counter"

module Verse
  module Distributed
    module Impl
      # In-memory implementation of Verse::Distributed::Counter.
      # This implementation is thread-safe.
      #
      # Counters are stored with their values and optional expiration timestamps.
      # TTL is handled passively (checked on access).
      class MemoryCounter
        include Verse::Distributed::Counter

        def initialize(_config = {})
          @counters = {} # { counter_name => { value: Integer, expires_at: Time } }
          @mutex = Mutex.new
          # @ttl_check_interval = config.fetch(:ttl_check_interval, 60) # For proactive GC
          # @stop_gc_thread = false
          # start_gc_thread unless config[:skip_gc_thread]
        end

        def increment(counter_name, amount = 1, ttl: nil, now: Time.now)
          @mutex.synchronize do
            check_and_expire_counter(counter_name)

            entry = @counters[counter_name] || { value: 0, expires_at: nil }
            entry[:value] += amount
            entry[:expires_at] = ttl ? now + ttl : entry[:expires_at] # Update TTL if provided

            @counters[counter_name] = entry
            entry[:value]
          end
        end

        # decrement is handled by the abstract module using increment(key, -amount)

        def get(counter_name, now: Time.now)
          @mutex.synchronize do
            check_and_expire_counter(counter_name, now:)
            @counters[counter_name] ? @counters[counter_name][:value] : nil
          end
        end

        def set(counter_name, value, ttl: nil, now: Time.now)
          @mutex.synchronize do
            # No need to check expiry before a direct set, as it overwrites.
            expires_at = ttl ? now + ttl : nil
            @counters[counter_name] = { value: value, expires_at: expires_at }
          end
          nil # void return
        end

        def delete(counter_name)
          @mutex.synchronize do
            # No need to check expiry, just remove if present.
            !!@counters.delete(counter_name) # Returns true if deleted, false otherwise
          end
        end

        private

        def check_and_expire_counter(counter_name, now: Time.now)
          entry = @counters[counter_name]
          return unless entry && entry[:expires_at] && entry[:expires_at] <= now

          @counters.delete(counter_name)
        end
      end
    end
  end
end
