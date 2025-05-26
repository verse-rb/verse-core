require "thread" # For Mutex
require "securerandom" # For lock tokens
require_relative "../../distributed_lock"
require_relative "../../errors"

module Verse
  module Util
    module Impl
      module Memory
        # In-memory implementation of Verse::Util::DistributedLock.
        # This implementation is thread-safe.
        #
        # Locks are stored with their tokens and expiration times.
        # A passive cleanup approach is used for expired locks (checked on access).
        class DistributedLock
          include Verse::Util::DistributedLock

          def initialize(config = {})
            @locks = {} # { lock_key => { token: "...", expires_at: Time } }
            @mutex = Mutex.new
            # @ttl_check_interval = config.fetch(:ttl_check_interval, 60) # For proactive GC if implemented
            # @stop_gc_thread = false
            # start_gc_thread unless config[:skip_gc_thread]
          end

          def acquire(lock_key, requested_ttl_ms, acquire_timeout_ms)
            deadline = Time.now + (acquire_timeout_ms / 1000.0)
            token = SecureRandom.hex(16)
            expires_at = Time.now + (requested_ttl_ms / 1000.0)

            loop do
              @mutex.synchronize do
                # Clean up expired lock for this key first
                check_and_expire_lock(lock_key)

                unless @locks.key?(lock_key)
                  @locks[lock_key] = { token: token, expires_at: expires_at }
                  return token
                end
              end # Release mutex

              return nil if Time.now >= deadline # Timeout exceeded
              sleep(0.01) # Short sleep before retrying
            end
          end

          def release(lock_key, lock_token)
            @mutex.synchronize do
              lock_info = @locks[lock_key]

              if lock_info && lock_info[:token] == lock_token
                # Check expiry again, though it might have been re-acquired if TTL was short
                if lock_info[:expires_at] > Time.now
                  @locks.delete(lock_key)
                  return true
                else
                  # Lock expired before release, or was already cleaned up
                  @locks.delete(lock_key) # Ensure it's gone
                  # Consider this a successful release of an expired lock if token matches,
                  # or false if strict "must be active" is required.
                  # For simplicity, if token matches, we say it's "released" even if it auto-expired.
                  return true # Or false if strict "must be active and held by this token"
                end
              else
                # Token mismatch or lock not found
                return false
              end
            end
          end

          def renew(lock_key, lock_token, new_ttl_ms)
            @mutex.synchronize do
              check_and_expire_lock(lock_key) # Clean up if expired

              lock_info = @locks[lock_key]

              if lock_info && lock_info[:token] == lock_token && lock_info[:expires_at] > Time.now
                lock_info[:expires_at] = Time.now + (new_ttl_ms / 1000.0)
                return true
              else
                return false # Lock not held by this token or expired
              end
            end
          end

          # def stop_gc
          #   @stop_gc_thread = true
          #   @gc_thread&.join
          # end

          private

          def check_and_expire_lock(lock_key)
            lock_info = @locks[lock_key]
            if lock_info && lock_info[:expires_at] <= Time.now
              @locks.delete(lock_key)
            end
          end

          # Optional: Proactive garbage collection thread for locks
          # def start_gc_thread
          #   @gc_thread = Thread.new do
          #     loop do
          #       break if @stop_gc_thread
          #       sleep @ttl_check_interval
          #       proactive_cleanup_locks
          #     end
          #   end
          # end

          # def proactive_cleanup_locks
          #   @mutex.synchronize do
          #     now = Time.now
          #     @locks.keys.each do |key| # Iterate on keys to allow deletion
          #       lock_info = @locks[key]
          #       if lock_info && lock_info[:expires_at] <= now
          #         @locks.delete(key)
          #       end
          #     end
          #   end
          # end
        end
      end
    end
  end
end
