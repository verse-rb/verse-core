# frozen_string_literal: true
module Verse
  module Auth
    class ScopeDSL
      def initialize(context, action, resource, scopes, &block)
        @context = context

        @scope = @context.can?(@action, @resource, &block)

        context.reject! unless scope

        scopes.each do |x|
          x = x.to_s

          next if x == "custom"
          method = "#{x}?"

          define_singleton_method(method) do |&block|
            next unless x == scope

            @result = block.call(scope)
          end
        end

        block.call(self)
      end

      # Is used with custom scopes.
      # @param scope [String] the scope to check
      def custom?(&block)
        next unless @scope == "custom"

        context.custom_scope
      end

      def else?(&block)
        @else = block
      end

      def result
        @result ||= @else&.call(self)
        @result
      end

      def reject!
        @context.reject!
      end
    end
  end
end