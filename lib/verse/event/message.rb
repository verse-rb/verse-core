# frozen_string_literal: true

module Verse
  module Event
    class Message
      attr_reader :headers, :content, :reply_to, :manager

      def initialize(content, manager: nil, headers: {}, reply_to: nil)
        @manager = manager

        @content = content
        @headers = headers
        @reply_to = reply_to

        to_msgpack
      end

      def reply(content, headers: {})
        raise "cannot reply to: empty reply channel or no manager" unless allow_reply?

        @manager.publish(@reply_to, content, headers:)
      end

      def to_msgpack
        {
          content:,
          headers:,
          reply_to:
        }.to_msgpack
      rescue => e
        binding.pry
      end

      def allow_reply?
        @reply_to && @reply_to != "" && @manager
      end

      def ack
        raise NotImplementedError, "only in inherited classes"
      end
    end
  end
end
