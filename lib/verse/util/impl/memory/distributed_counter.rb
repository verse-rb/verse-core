require "thread" # For Mutex
require_relative "../../distributed_counter"

module Verse
  module Util
    module Impl
      module Memory
        # In-memory implementation of Verse::Util::DistributedCounter.
        # This implementation is thread-safe.
        #
        # Counters are stored with their values and optional expiration timestamps.
        # TTL is handled passively (checked on access).
        class DistributedCounter
          include Verse::Util::DistributedCounter

          def initialize(config = {})
            @counters = {} # { counter_name => { value: Integer, expires_at: Time } }
            @mutex = Mutex.new
            # @ttl_check_interval = config.fetch(:ttl_check_interval, 60) # For proactive GC
            # @stop_gc_thread = false
            # start_gc_thread unless config[:skip_gc_thread]
          end

          def increment(counter_name, amount = 1, ttl: nil)
            @mutex.synchronize do
              check_and_expire_counter(counter_name)

              entry = @counters[counter_name] || { value: 0, expires_at: nil }
              entry[:value] += amount
              entry[:expires_at] = ttl ? Time.now + ttl : entry[:expires_at] # Update TTL if provided

              @counters[counter_name] = entry
              entry[:value]
            end
          end

          # decrement is handled by the abstract module using increment(key, -amount)

          def get(counter_name)
            @mutex.synchronize do
              check_and_expire_counter(counter_name)
              @counters[counter_name] ? @counters[counter_name][:value] : nil
            end
          end

          def set(counter_name, value, ttl: nil)
            @mutex.synchronize do
              # No need to check expiry before a direct set, as it overwrites.
              expires_at = ttl ? Time.now + ttl : nil
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

          # def stop_gc
          #   @stop_gc_thread = true
          #   @gc_thread&.join
          # end

          private

          def check_and_expire_counter(counter_name)
            entry = @counters[counter_name]
            if entry && entry[:expires_at] && entry[:expires_at] <= Time.now
              @counters.delete(counter_name)
            end
          end

          # Optional: Proactive garbage collection thread for counters
          # def start_gc_thread
          #   @gc_thread = Thread.new do
          #     loop do
          #       break if @stop_gc_thread
          #       sleep @ttl_check_interval
          #       proactive_cleanup_counters
          #     end
          #   end
          # end

          # def proactive_cleanup_counters
          #   @mutex.synchronize do
          #     now = Time.now
          #     @counters.keys.each do |key| # Iterate on keys to allow deletion
          #       entry = @counters[key]
          #       if entry && entry[:expires_at] && entry[:expires_at] <= now
          #         @counters.delete(key)
          #       end
          #     end
          #   end
          # end
        end
      end
    end
  end
end
