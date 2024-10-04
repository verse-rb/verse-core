# frozen_string_literal: true

require_relative "./base"

module Verse
  module Error
    class ValidationFailed < Base
      def initialize(result = nil)
        if result.respond_to?(:errors)
          super(map_errors(result.errors))
          @source = result.errors
        elsif result.is_a?(String)
          super(result)
        else
          super("verse.errors.validation_failed")
        end
      end

      def map_errors(errors)
        errors.map do |field, messages|
          "#{field}: #{messages.join(", ")}"
        end.flatten.join(", ")
      end

      http_code 422
    end
  end
end
