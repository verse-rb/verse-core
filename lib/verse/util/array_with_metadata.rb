# frozen_string_literal: true

module Verse
  module Util
    # ArrayWithMetadata is a simple wrapper around an array that allows you to
    # store metadata with it.
    #
    # Metadata can be counter for SQL queries, where the array size won't
    # match the size of the collection outputed because of pagination.
    #
    # It could be links to the next and previous page, or filters
    # used to generate the output.
    class ArrayWithMetadata
      attr_accessor :metadata

      # initialize with delegated array and metadata
      # @param delegated [Array] array to delegate to
      # @param metadata [Hash] metadata to store
      def initialize(delegated, metadata: {})
        @delegated  = delegated
        @metadata   = metadata
      end

      # delegate respond_to? to delegated array
      def respond_to_missing?(method_name, include_private = false)
        @delegated.respond_to?(method_name) || super
      end

      # delegate to delegated array any methods.
      def method_missing(method, *args, &block)
        @delegated.send(method, *args, &block)
      end

      def to_json(*opts)
        {
          data: @delegated,
          metadata: @metadata
        }.to_json(*opts)
      end

      # delegate equality to delegated array
      def ==(other)
        @delegated == other || super
      end
    end
  end
end
