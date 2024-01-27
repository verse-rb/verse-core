# frozen_string_literal: true

require_relative "./base"

module Verse
  module Error
    class ValidationFailed < Base
      def initialize(result = nil)
        super("verse.errors.validation_failed")

        @source = result&.errors
      end

      def message
        return "validation failed" unless @result

        @result.errors.each do |key, errors|
          puts "#{key}: "
          puts errors.map{ |x| "  - #{x}" }.join("\n")
        end
      end

      http_code 422
    end
  end
end
