# frozen_string_literal: true

module Verse
  module Util
    module Errors
      # Base error class for Verse::Util components
      class UtilError < Verse::Error::BaseStandardError; end

      # Errors related to distributed lock operations
      class LockError < UtilError; end

      # Raised when acquiring a lock times out
      class LockAcquisitionTimeoutError < LockError; end

      # Raised when releasing a lock fails (e.g., token mismatch, lock not held)
      class LockReleaseError < LockError; end

      # Raised when renewing a lock fails
      class LockRenewalError < LockError; end

      # Errors related to distributed set or counter operations
      class ResourceError < UtilError; end

      # Raised when there's a configuration issue with a utility
      class ConfigurationError < UtilError; end

      class SerializationError < UtilError; end
    end
  end
end
