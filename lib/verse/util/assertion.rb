# frozen_string_literal: true

module Verse
  module Util
    module Assertion
      module_function

      def assert(test, message = nil, klass = RuntimeError)
        return if test

        raise klass, yield if block_given?

        raise klass, message || "Assertion failed"
      end
    end
  end
end
