# frozen_string_literal: true
module Verse
  module Auth
    # object describing authorizations
    class Context
      AuthError = Class.new(StandardError)
      UnauthorizedError = Class.new(AuthError)

      attr_reader :custom_scopes

      def initialize
        @custom_scopes = {}
      end

      # Check whether we can perform an action on a resource.
      # Use a block to define the scoped resource for given action.
      # Example:
      #
      # ```
      #   auth_context.can!(:read, :user) do |scope|
      #     scope.all?{ table }                               # Give access to all users
      #     scope.any?{ |id| table.where(id: id) }            # Give access to a specific user
      #     scope.me?{ table.where(id: auth_context.user_id)} # Give access to the current user
      #     scope.else?(&:reject!) # Reject all other cases. This is the default behavior if a scope is not found.
      #   end
      # ```
      #
      # @param action [Symbol] the action on the resource we want to check
      # @param resource [Symbol] the resource we want to check
      # @param block [Proc] the block used to define the scope.
      #
      # @return [Object] the result of the selected block
      def can!(action, resource, &block)
        scopes = list_scopes(action, resource)

        mark_as_checked!
        result = ScopeDsl.new(scopes, &block).result

        if result.nil?
          raise UnauthorizedError, "unauthorized"
        end
      end

      def can?(caction, resource)
        raise UnimplementedError, "can? must be implemented"
      end

      alias_method :mark_as_checked!, :no_authorization!

      # said that the security context has been checked.
      def mark_as_checked!
        @checked = true
      end

      def checked?
        !!@checked
      end

      def custom_scope(resource)
        @custom_scopes[resource.to_s]
      end

      protected

      def list_scopes(action, resource)
        raise UnimplementedError, "list_scopes must be implemented"
      end

    end
  end
end
