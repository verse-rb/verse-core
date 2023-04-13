require_relative "./base"

module Verse
  module Error
    class CannotCreateRecord < Base
      http_code 422
      message "verse.errors.cannot_create_record"
    end
  end
end