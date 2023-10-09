# frozen_string_literal: true

module Verse
  module Spec
    module ServiceHelper
      def service(role = :system)
        @service       ||= {}
        @service[role] ||= Verse::Util::Reflection.constantize(self.class.top_level_description).new(
          Verse::Auth::Context[:system]
        )
      end
    end
  end
end