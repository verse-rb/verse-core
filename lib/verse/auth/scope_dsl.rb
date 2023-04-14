# frozen_string_literal: true

module Verse
  module Auth
    class ScopeDSL
      def initialize(context, action, resource, &block)
        @action = action.to_sym
        @resource = resource.to_sym

        @context = context

        @scope = @context.can?(action.to_sym, resource.to_sym).to_sym

        context.reject! unless @scope

        @scopes = @context.list_scopes(@action, @resource)

        @scopes.lazy.map(&:to_sym).select{ |x| x != :custom }.each do |scope|
          define_singleton_method("#{scope}?") do |&block|
            return unless @scope == scope

            @result = block.call
          end
        end

        block.call(self)
      end

      # Is used with custom scopes.
      # @param scope [String] the scope to check
      def custom?(&block)
        return unless @scope == :custom

        @result = block.call(
          @context.custom_scope(@resource)
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
