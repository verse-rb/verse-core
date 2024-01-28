# frozen_string_literal: true

require_relative "./base"

module Verse
  module Error
    class ValidationFailed < Base
      def initialize(result = nil)
        if result.respond_to?(:errors)
          super("verse.errors.validation_failed")
          @source = result&.errors
        elsif(result.is_a?(String))
          super(result)
        else
          super("verse.errors.validation_failed")
        end
      end

      http_code 422
    end
  end
end
