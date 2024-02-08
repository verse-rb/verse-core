# frozen_string_literal: true

module Verse
  module Event
    class Message
      attr_reader :headers, :content, :reply_to, :manager, :key

      def initialize(manager, content, headers: {}, key: nil, reply_to: nil)
        @content = content
        @headers = headers
        @reply_to = reply_to
        @manager = manager
        @key = key
      end

      def reply(content, headers: {})
        raise "cannot reply to: empty reply channel" unless @reply_to

        @manager.publish(@reply_to, content, headers: headers, key: key)
      end

      def allow_reply?
        @reply_to && @reply_to != ""
      end

      def ack
        raise NotImplementedError, "only in inherited classes"
      end
    end
  end
end
