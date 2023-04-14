# frozen_string_literal: true

module Verse
  module Util
    module Assertion
      extend self

      # Asserts that the given test is true. If not, an exception is raised.
      # The exception can be specified with the `klass` argument.
      # If a block is given, it is evaluated and its return value is used as
      # the exception message.
      # If no block is given, the `message` argument is used as the exception
      # message.
      #
      # @param test [Boolean] the test to assert
      # @param message [String] the message to use if the test fails
      # @param klass [Class] the exception class to raise
      # @yieldreturn [String] the message to use if the test fails
      #
      # @return [void]
      def assert(test, message = nil, klass = RuntimeError)
        return if test

        raise klass, yield if block_given?

        raise klass, message || "Assertion failed"
      end
    end
  end
end
