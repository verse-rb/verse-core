# frozen_string_literal: true

module Verse
  module Util
    module HashUtil
      extend self

      # Recursively converts all keys in a hash to symbols.
      #
      # @param hash [Hash] the hash to convert
      # @return [Hash] the converted hash
      def deep_symbolize_keys(hash)
        hash.map do |k, v|
          v = case v
              when Hash
                deep_symbolize_keys(v)
              when Array
                v.map{ |x| deep_symbolize_keys(x) }
              else
                v
              end

          [k.to_sym, v]
        end.to_h
      end
    end
  end
end
