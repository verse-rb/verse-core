# frozen_string_literal: true

require_relative "./class_methods"

module Verse
  module Service
    # Base class for your application services
    # @abstract
    class Base
      extend ClassMethods

      attr_reader :auth_context, :metadata

      def initialize(auth_context, metadata = {})
        @auth_context = auth_context
        @metadata     = metadata
      end

      # Setup specific metadata for the current block then revert to
      # existing metadata.
      #
      # @param metadata [Hash] metadata to be merged with the current metadata
      # @yield block to be executed with the new metadata
      # @return [Object] the result of the block
      def with_metadata(metadata)
        old_metadata = @metadata
        @metadata = @metadata.merge(metadata)
        yield
      ensure
        @metadata = old_metadata
      end
    end
  end
end
