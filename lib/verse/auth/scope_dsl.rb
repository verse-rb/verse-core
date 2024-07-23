# frozen_string_literal: true

module Verse
  module Auth
    class ScopeDSL
      def initialize(context, action, resource, &block)
        @action = action.to_sym
        @resource = resource.to_sym

        @context = context

        @scope = @context.can?(action.to_sym, resource.to_sym)

        if @scope
          @scope = @scope.to_sym
        end

        block.call(self)
      end

      def method_missing(method_name, *_args, &block)
        return false unless @scope
        return false unless method_name == :"#{@scope}?"

        @result = block.call(self)
      end

      def respond_to_missing?(method_name, include_private = false)
        super if method_name.to_s !~ /^[a_z0-9]+\?$/
        true
      end

      # Is used with custom scopes.
      # @param scope [String] the scope to check
      def custom?(key = nil, &block)
        key ||= @resource.to_sym

        return unless @scope == :custom

        @result = block.call(
          @context[key]
        )
      end

      def else?(&block)
        @else = block
      end

      def result
        @result ||= @else&.call(self)

        @context.reject!("unauthorized action `#{@action}` on `#{@resource}`") unless @result

        @result
      end

      def reject!
        @context.reject!
      end
    end
  end
end
