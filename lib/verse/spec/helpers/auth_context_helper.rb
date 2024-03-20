# frozen_string_literal: true

module Verse
  module Spec
    module AuthContextHelper
      attr_accessor :current_auth_context

      def self.included(base)
        base.around do |example|
          user = example.metadata[:as]
          params = Verse::Spec.users.fetch(user) {
            raise "user `#{user}` not found. Please add it with Verse::Spec.add_user"
          }

          @current_auth_context = Verse::Auth::Context.from_role(
            params[:role],
            custom_scopes: params[:scopes],
            metadata: params[:user_context]
          )

          example.run
        ensure
          @current_auth_context = nil
        end
      end
    end
  end
end
