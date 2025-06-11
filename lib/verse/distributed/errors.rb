# frozen_string_literal: true

require_relative "../error/base"

module Verse
  module Distributed
    # Base error class for Verse::Util components
    class Error < Verse::Error::Base; end

    # Errors related to distributed lock operations
    class LockError < Error; end

    # Raised when acquiring a lock times out
    class LockAcquisitionTimeout < LockError; end

    # Raised when releasing a lock fails (e.g., token mismatch, lock not held)
    class LockReleaseError < LockError; end

    # Raised when renewing a lock fails
    class LockRenewalError < LockError; end

    # Errors related to distributed set or counter operations
    class ResourceError < Error; end

    # Raised when there's a configuration issue with a utility
    class ConfigurationError < Error; end

    class SerializationError < Error; end
  end
end
