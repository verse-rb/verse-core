# frozen_string_literal: true

module Verse
  module Error
    class Base < StandardError
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
          return @http_code  if @http_code

          inherited_code = ancestors.lazy.select{ |x| x!=self }.find{ |x| x.respond_to?(:http_code) }&.http_code
          return inherited_code || 500
        end
      end

      def self.message(message = nil)
        if message
          @message = message
        else
          return @message if @message

          inherited_message = ancestors.lazy.select{ |x| x!=self }.find{ |x| x.respond_to?(:message) }&.message
          return inherited_message || "verse.errors.server_error"
        end
      end
    end
  end
end
