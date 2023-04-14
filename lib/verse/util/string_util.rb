# frozen_string_literal: true

module Verse
  module Util
    module StringUtil
      extend self

      # Convert a string to camel case
      # @param string [String] the string to convert
      # @param uppercase_first_letter [Boolean] whether to uppercase the first letter
      # @return [String] the converted string
      def camelize(string, uppercase_first_letter: true)
        string = if uppercase_first_letter
                   string.sub(/^[a-z\d]*/, &:capitalize)
                 else
                   string.sub(/^(?:(?=\b|[A-Z_])|\w)/, &:downcase)
                 end

        string.gsub(%r{(?:_|(/))([a-z\d]*)}) { "#{$1}#{$2.capitalize}" }.gsub("/", "::")
      end

      # Convert a string to snake case
      # @param string [String] the string to convert
      # @return [String] the converted string
      def underscore(string)
        string.gsub(/::/, "/")
              .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
              .gsub(/([a-z\d])([A-Z])/, '\1_\2')
              .tr("-", "_")
              .downcase
      end

    end
  end
end
