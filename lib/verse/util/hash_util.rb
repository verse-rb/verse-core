# frozen_string_literal: true

module Verse
  module Util
    module HashUtil
      extend self

      # Recursively converts all keys in a hash to symbols.
      #
      # @param hash [Hash] the hash to convert
      # @return [Hash] the converted hash
      def deep_symbolize_keys(value)
        case value
        when Array
          value.map{ |x| deep_symbolize_keys(x) }
        when Hash
          value.map do |k, v|
            [k.to_sym, deep_symbolize_keys(v)]
          end.to_h
        else
          value
        end
      end
    end
  end
end
