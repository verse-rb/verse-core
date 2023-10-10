# frozen_string_literal: true

module Verse
  module Spec
    module ContextHelper
      attr_writer :current_context

      def current_context(role = :system)
        @current_context ||= Verse::Auth::Context[role]
      end
    end
  end
end
