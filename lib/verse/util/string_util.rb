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

      # when given a string with leading spaces, it will remove the same amount
      # of spaces from each line.
      # This is useful with heredocs, where the leading spaces are used for
      # indentation, but you want to remove them when the string is used.
      #
      # @param string [String] the string to strip the indentation from
      # @return [String] the string with the indentation removed
      def strip_indent(string)
        min_indent = string.scan(/^[ \t]*(?=\S)/).min
        indent = min_indent ? min_indent.size : 0
        string.gsub(/^[ \t]{#{indent}}/, "")
      end

      # Convert a string to snake case
      # @param string [String] the string to convert
      # @return [String] the converted string
      def underscore(string)
        string.gsub("::", "/")
              .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
              .gsub(/([a-z\d])([A-Z])/, '\1_\2')
              .tr("-", "_")
              .downcase
      end

      # Convert a string to title case
      # @param string [String] the string to convert
      # @return [String] the converted string
      def titleize(string)
        # Use 'tr' to replace underscores and '::' in one go
        string = string.tr("_", " ").gsub("::", " ")
                       .gsub(/([a-z])([A-Z])/, '\1 \2') # Handle camelCase
        # Split by spaces, capitalize each word, and join them back with a space
        string.split(/([^\w])/).map(&:capitalize).join
      end
    end
  end
end
