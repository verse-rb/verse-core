# frozen_string_literal: true

module Verse
  module Util
    # A future is a value that will be computed asynchronously.
    # It is useful to avoid blocking the current thread.
    # This is very close to the native thread interfaces.
    class Future

      def initialize(&block)
        @thread = Thread.new do
          block.call
        rescue Exception => e
          @error = e
          nil
        end

        @thread.name = "Future"
        @thread.report_on_exception = false
      end

      def success?
        done? && !error?
      end

      def done?
        !@thread.alive?
      end

      def error?
        !!@error
      end

      def error
        @error
      end

      def wait
        if done?
          raise @error if @error

          @result
        else
          begin
            @result = @thread.value

            raise @error if @error

            @result
          rescue Exception => e
            @error = e
            raise
          ensure
            @done = true
          end
        end
      end

      def cancel
        @thread.raise Timeout::Error, "canceled by user"
      end

    end
  end
end
