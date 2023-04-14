require_relative "./base"

module Verse
  module Error
    class ValidationFailed < Base
      attr_reader :contract

      def initialize(contract = nil)
        super("verse.errors.validation_failed")

        @contract = contract

        @source =
          if contract
            dry_errors_flattener contract.errors.to_h
          else
            {}
          end
      end

      http_code 422
      message "verse.errors.validation_failed"

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
