# frozen_string_literal: true

require_relative "../exposition/handler"

module Verse
  module Auth
    # Check if the authorization context has been checked.
    class CheckAuthenticationHandler < Verse::Exposition::Handler
      class << self
        def disable
          disabled = @disabled
          @disabled = true
          yield
        ensure
          @disabled = disabled
        end

        attr_reader :disabled
      end

      def call
        output = call_next

        return output if self.class.disabled || exposition.auth_context.checked?

        raise Error::Authorization,
              "The authorization context " \
              "hasn't been checked during the call. " \
              "Please ensure that you call `auth_context.can!` " \
              " or mark the context as checked with `auth_context.mark_as_checked!`"
      end
    end
  end
end
