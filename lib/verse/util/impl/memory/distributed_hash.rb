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
            ).to_f

            @stop = false # Flag to stop the cleanup thread
            @cond = new_cond # Condition variable for the cleanup thread

            puts "cleanup_interval_seconds: #{@cleanup_interval_seconds}"
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
              if entry&.fetch(:expires_at, NEVER_EXPIRES)&.<=(now_timestamp)
                @store.delete(key) # Clean up expired entry
                # If it was expired, it means it wasn't accessible via get.
                # The return value of delete usually indicates if an *active* item was removed.
                # So, if it was expired, it's like it wasn't there to be actively deleted.
                return false
              end

              !!@store.delete(key)
            end
          end

          def clear_all
            mon_synchronize do
              @store.clear
            end

            nil
          end

          # Stops the cleanup thread gracefully.
          def stop_cleanup_thread
            return unless @cleanup_thread&.alive?

            mon_synchronize do
              @stop = true
              @cond.signal # Wake up the thread if it's waiting
            end
            @cleanup_thread.join # Wait for the thread to finish
            @cleanup_thread = nil
          end

          def cleanup(now: Time.now)
            if @cleanup_thread&.alive?
              mon_synchronize do
                @cond.signal
                @cond.wait
              end
            else
              cleanup_expired_keys(now:) # If no thread, do cleanup immediately
            end
          end

          private

          def start_cleanup_thread
            @cleanup_thread = Thread.new do
              loop do
                # Lock is acquired to check @stop and wait on @cond
                should_stop = mon_synchronize do
                  @cond.wait(@cleanup_interval_seconds) unless @stop
                  @stop
                end

                break if should_stop # Exit loop if stop flag is true

                begin
                  cleanup_expired_keys(now: Time.now)
                rescue StandardError => e
                  # In a real app, Verse.logger should be used if available and configured
                  # For now, print to stderr to avoid dependency if logger isn't set up.
                  warn "Error in DistributedHash cleanup thread: #{e.message}\n#{e.backtrace.join("\n")}"
                  # If an error occurs, we still want to respect the interval before retrying,
                  # but the wait above already handled the primary sleep.
                  # A short additional sleep might be useful if errors are persistent.
                  mon_synchronize { @cond.wait(1) unless @stop } # Short wait on error, check stop again
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

            ensure
              @cond.signal # Signal that cleanup is done, if any threads are waiting
            end
          end
        end
      end
    end
  end
end
