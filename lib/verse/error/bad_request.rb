# frozen_string_literal: true

require_relative "./base"

module Verse
  module Error
    class BadRequest < Base
      http_code 400
      message "verse.errors.bad_request"

      def initialize(msg = nil)
        super(message, details: { message: msg }.compact)
      end
    end
  end
end
