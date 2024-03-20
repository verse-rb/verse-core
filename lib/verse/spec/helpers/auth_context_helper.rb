# frozen_string_literal: true

module Verse
  module Spec
    module AuthContextHelper
      attr_accessor :current_auth_context

      def self.included(base)
        base.before do
          @current_auth_context = Verse::Auth::Context.new(
            user: Verse::Spec[:default_user],
            scopes: Verse::Spec[:default_user][:scopes]
          )
        end
      end
    end
  end
end
