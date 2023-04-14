# frozen_string_literal: true

module Verse
  module Auth
    class ScopeDSL
      def initialize(context, action, resource, &block)
        @action = action.to_sym
        @resource = resource.to_sym

        @context = context

        @scope = @context.can?(action.to_sym, resource.to_sym)

        context.reject! unless @scope

        @scope = @scope.to_sym

        block.call(self)
      end

      def method_missing(method_name, *_args, &block)
        return false unless "#{@scope}?".to_sym == method_name

        @result = block.call(self)
      end

      def respond_to_missing?(method_name, include_private = false)
        method_name.to_s =~ /^[a_z0-9]+\?$/ || super
      end

      # Is used with custom scopes.
      # @param scope [String] the scope to check
      def custom?(&block)
        return unless @scope == :custom

        @result = block.call(
          @context[@resource]
        )
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
