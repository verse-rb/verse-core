# frozen_string_literal: true

module Verse
  module Spec
    module ContextHelper
      attr_accessor :auth_context

      def current_context(role = :system)
        @auth_context ||= Verse::Auth::Context[role]
      end

    end
  end
end
