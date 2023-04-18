# frozen_string_literal: true

require_relative "../exposition/handler"

module Verse
  module Auth
    # Check if the authorization context has been checked.
    class CheckAuthenticationHandler < Verse::Exposition::Handler
      def call
        output = call_next

        return output if exposition.auth_context.checked?

        raise Error::Authorization,
              "The authorization context" \
              "hasn't been checked during the call. " \
              "Please ensure that you call `auth_context.can!` " \
              " or mark the context as checked with `auth_context.mark_as_checked!`"
      end
    end
  end
end
