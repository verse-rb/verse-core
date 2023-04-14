# frozen_string_literal: true

module Verse
  module Error
    class Base < RuntimeError
      attr_reader :meta, :source, :details

      def initialize(msg = nil, details: {}, meta: {})
        super(msg || self.class.message)

        @details = details
        @meta = meta
      end

      def self.code(value = nil)
        if value
          @code = value
        else
          @code || http_code
        end
      end

      def self.http_code(value = nil)
        if value
          @http_code = value
        else
          @http_code || 500
        end
      end

      def self.message(message = nil)
        if message
          @message = message
        else
          @message || "verse.errors.server_error"
        end
      end
    end
  end
end
