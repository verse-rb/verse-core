module Verse
  module Spec
    module AsUserHelper
      attr_reader :current_auth_context

      def as_user(username, &block)
        old_context = @current_auth_context

        params = Verse::Spec.users.fetch(username) {
          raise "user `#{username}` not found. Please add it with Verse::Spec.add_user"
        }

        @current_auth_context = Verse::Auth::Context.from_role(
          params[:role],
          custom_scopes: params[:scopes],
          metadata: params[:user_data]
        )

        block.call
      ensure
        @current_auth_context = old_context
      end
    end
  end
end
