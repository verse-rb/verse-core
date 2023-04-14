# frozen_string_literal: true

require_relative "./base"

module Verse
  module Error
    class NotFound < Base
      http_code 404
      message "verse.errors.not_found"
    end
  end
end
