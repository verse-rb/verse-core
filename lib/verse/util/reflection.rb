# frozen_string_literal: true

module Verse
  module Util
    module Reflection
      extend self

      # Get a given constant from the string
      # @param string [String] the string to get the constant from
      # @param object_space [Object] the object space to search in
      # @return [Object] the constant
      def get(string, object_space = ObjectSpace)
        if string[0..1] == "::"
          string = string[2..]
        end

        get_path(string.split("::"), object_space)
      rescue NameError => e
        raise NameError, "Unable to find constant #{string}", e.backtrace
      end

      private

      # :nodoc:
      def get_path(path, object_space = ObjectSpace)
        return object_space if path.empty?

        constant = object_space.const_get(path.first)

        get_path(path[1..], constant)
      end
    end
  end
end
