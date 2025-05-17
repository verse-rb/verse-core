# frozen_string_literal: true

require_relative "./base"

module Verse
  module Error
    class AuthenticationFailed < Base
      http_code 401
      message "Authentication failed"
    end
  end
end
