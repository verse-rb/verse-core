# frozen_string_literal: true

require_relative "./base"

module Verse
  module Error
    class ValidationFailed < Base
      attr_reader :contract

      def initialize(result = nil)
        super("verse.errors.validation_failed")

        @result = result

        @source =
          if contract
            dry_errors_flattener contract.errors.to_h
          else
            {}
          end
      end

      def message
        return "validation failed" unless @result
        return @result.errors.to_s
      end

      http_code 422

      private

      def dry_errors_flattener(hash, model = nil, out = [])
        hash.each do |k, v|
          case v
          when Array
            v.each do |value|
              out << case value
                     when Hash
                       { model: model, parameter: k, key: value[:text], details: value.except(:text) }
                     else
                       { model: model, parameter: k, key: value }
                     end
            end
          else # Hash
            dry_errors_flattener(v, [model, k].compact.join("."), out)
          end
        end

        out
      end
    end
  end
end
