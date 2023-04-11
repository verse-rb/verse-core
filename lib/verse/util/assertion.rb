module Verse
  module Util
    module Assertion
      module_function

      def assert(test, message = nil, klass = RuntimeError)
        return if test

        if block_given?
          raise klass.new(yield)
        else
          raise klass.new(message || "Assertion failed")
        end
      end
    end
  end
end