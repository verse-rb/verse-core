# frozen_string_literal: true

require_relative "./base"

module Verse
  module Error
    class RecordNotFound < Base
      http_code 404
      message "verse.errors.record_not_found"
    end
  end
end
