# frozen_string_literal: true

require_relative "./base"

module Verse
  module Error
    class Unauthorized < Authorization
      http_code 403
      message "verse.errors.unauthorized"
    end
  end
end
