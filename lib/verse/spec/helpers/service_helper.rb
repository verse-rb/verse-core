# frozen_string_literal: true

module Verse
  module Spec
    module ServiceHelper
      def service(user = nil)
        auth_context = nil

        if user
          params = Verse::Spec.users.fetch(user) {
            raise "user `#{user}` not found. Please add it with Verse::Spec.add_user"
          }

          auth_context = Verse::Auth::Context.from_role(
            params[:role],
            custom_scopes: params[:scopes],
            metadata: params[:user_data]
          )
        else
          auth_context = respond_to?(:current_auth_context) ? current_auth_context : nil
        end

        auth_context ||= Verse::Auth::Context[:system]

        @service ||= {}
        @service[user] ||= Verse::Util::Reflection.constantize(self.class.top_level_description).new(
          auth_context
        )
      end
    end
  end
end
