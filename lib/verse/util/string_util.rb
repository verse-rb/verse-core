# frozen_string_literal: true

module Verse
  module Util
    module StringUtil
      extend self

      def camelize(string, uppercase_first_letter = true)
        string = if uppercase_first_letter
                   string.sub(/^[a-z\d]*/, &:capitalize)
                 else
                   string.sub(/^(?:(?=\b|[A-Z_])|\w)/, &:downcase)
                 end

        string.gsub(%r{(?:_|(/))([a-z\d]*)}) { "#{$1}#{$2.capitalize}" }.gsub("/", "::")
      end
    end
  end
end
