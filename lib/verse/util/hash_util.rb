# frozen_string_literal: true

module Verse
  module Util
    module HashUtil
      module_function

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
