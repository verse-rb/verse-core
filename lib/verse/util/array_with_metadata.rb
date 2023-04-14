# frozen_string_literal: true

module Verse
  module Util
    class ArrayWithMetadata
      attr_accessor :metadata

      def initialize(delegated, metadata: {})
        @delegated  = delegated
        @metadata   = metadata
      end

      def respond_to_missing?(method_name, include_private = false)
        @delegated.respond_to?(method_name) || super
      end

      def method_missing(method, *args, &block)
        # delegate to sub array any methods.
        @delegated.send(method, *args, &block)
      end
    end
  end
end
