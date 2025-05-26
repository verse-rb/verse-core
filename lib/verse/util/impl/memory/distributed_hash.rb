require "monitor" # For MonitorMixin
require_relative "../../distributed_hash"

module Verse
  module Util
    module Impl
      module Memory
        # In-memory implementation of Verse::Util::DistributedHash (simple key-value store).
        # This implementation is thread-safe using MonitorMixin.
        #
        # TTL is handled by storing expiration timestamps (as floats) and checking them on access.
        # Methods accept an optional `now` parameter (as a Time object) for testability.
        class DistributedHash
          include Verse::Util::DistributedHash
          include MonitorMixin # For thread-safety

          # Using a large float to represent 'never expires'
          NEVER_EXPIRES = Float::MAX
          DEFAULT_CLEANUP_INTERVAL_SECONDS = 60

          attr_reader :cleanup_thread

          def initialize(config = {})
            @store = {}
            super() # Important for MonitorMixin to initialize

            @cleanup_interval_seconds = config.fetch(
              :cleanup_interval_seconds,
              DEFAULT_CLEANUP_INTERVAL_SECONDS
            ).to_i

            start_cleanup_thread if @cleanup_interval_seconds > 0
          end

          def get(key, now: Time.now)
            now_timestamp = now.to_f
            mon_synchronize do
              entry = @store[key]
              return nil unless entry

              if entry.fetch(:expires_at, NEVER_EXPIRES) <= now_timestamp
                @store.delete(key) # Expired
                return nil
              end

              entry[:value]
            end
          end

          def set(key, value, ttl: nil, now: Time.now)
            now_timestamp = now.to_f
            mon_synchronize do
              expires_at_timestamp = ttl ? now_timestamp + ttl : NEVER_EXPIRES
              @store[key] = { value: value, expires_at: expires_at_timestamp }
            end
            nil # void return
          end

          def delete(key, now: Time.now)
            now_timestamp = now.to_f
            mon_synchronize do
              entry = @store[key]
              # If entry exists and is expired, it's effectively already gone for a get,
              # but delete should still confirm its removal from the store.
              if entry&.fetch(:expires_at, NEVER_EXPIRES) <= now_timestamp
                @store.delete(key) # Clean up expired entry
                # If it was expired, it means it wasn't accessible via get.
                # The return value of delete usually indicates if an *active* item was removed.
                # So, if it was expired, it's like it wasn't there to be actively deleted.
                return false
              end

              @store.delete(key)
              return true
            end
          end

          def clear_all
            mon_synchronize do
              @store.clear
            end

            nil
          end

          private

          def start_cleanup_thread
            @cleanup_thread = Thread.new do
              loop do
                begin
                  # Sleep first, then cleanup. Or cleanup then sleep.
                  # Sleeping first means the first cleanup is delayed.
                  # Cleaning up first means immediate cleanup then sleep.
                  # Let's sleep first to give the application time to start.
                  sleep @cleanup_interval_seconds

                  # Perform cleanup
                  cleanup_expired_keys(now: Time.now)
                rescue StandardError => e
                  Verse.logger.error("Error in DistributedHash cleanup thread: #{e.message}")
                  Verse.logger.error(e.backtrace.join("\n"))
                  sleep 1
                end
              end
            end
          end

          def cleanup_expired_keys(now: Time.now)
            now_timestamp = now.to_f

            # The entire operation of iterating and deleting should be atomic
            # with respect to other operations on @store.
            mon_synchronize do
              # Iterate over a copy of keys to safely delete from the hash
              @store.keys.each do |key|
                entry = @store[key] # Re-fetch entry in case it was changed/deleted by another thread
                                    # just before this key was processed, though less likely with Monitor.
                if entry&.fetch(:expires_at, NEVER_EXPIRES) <= now_timestamp
                  @store.delete(key)
                end
              end
            end
          end
        end
      end
    end
  end
end
