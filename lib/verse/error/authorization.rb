# frozen_string_literal: true

require_relative "./base"

module Verse
  module Error
    class Authorization < Base
      http_code 401
      message "verse.errors.authorization"
    end
  end
end
