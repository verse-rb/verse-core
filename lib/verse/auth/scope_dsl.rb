# frozen_string_literal: true

module Verse
  module Auth
    class ScopeDSL
      def initialize(context, action, resource, &block)
        @action = action.to_sym
        @resource = resource.to_sym

        @context = context

        @scope = @context.can?(action.to_sym, resource.to_sym)

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

      # This method is used with custom scopes encoded in the token.
      #
      # @param key [String] the key used in the token to store the custom scope.
      #
      # @example
      #
      #  auth_context = Verse::Auth::Context.new(["users.read.custom"],
      #   custom_scopes: { users: [1,2,3] }
      #  )
      #  auth_context.can! :read, :user do |scope|
      #     scope.custom?(:users) do |users|
      #       puts users # will return [1,2,3]
      #     end
      #  end
      def custom?(key = nil, &block)
        key ||= @resource.to_sym

        return unless @scope == :custom

        @result = block.call(
          @context[key]
        )
      end

      # Is used when the scope is an array of elements.
      #
      # @param block [Proc] the block to execute when the scope
      # is an array.
      #
      # @example
      #   auth_context = Verse::Auth::Context.new(["users.read.{a,b,c}"])
      #   auth_context.can! :read, :user do |scope|
      #     scope.array? do |users|
      #     puts users # will return ["a", "b", "c"]
      #   end
      def array?(&block)
        return unless @scope.is_a?(Array)

        @result = block.call(@scope)
      end

      # If no block is matching the scope, then the else? block will be executed.
      # If no else? block is defined, then the action will be rejected.
      # @param block [Proc] the block to execute when no other block is matching.
      #
      # @example
      #
      #   auth_context = Verse::Auth::Context.new(["users.read.*"])
      #   auth_context.can! :write, :user do
      #     scope.else? do
      #       puts "No scope found"
      #       false
      #     end
      #   end
      def else?(&block)
        @else = block
      end

      # :nodoc:
      def result
        @result ||= @else&.call(self)

        @context.reject!("unauthorized action `#{@action}` on `#{@resource}`") unless @result

        @result
      end

      # Reject the action and raise an error.
      def reject!
        @context.reject!
      end
    end
  end
end
