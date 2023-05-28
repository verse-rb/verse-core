# frozen_string_literal: true

module Verse
  module Event
    class Message
      attr_reader :headers, :content, :reply_to, :manager

      def initialize(manager, content, headers: {}, reply_to: nil)
        @content = content
        @headers = headers
        @reply_to = reply_to
        @manager = manager
      end

      def reply(content, headers: {})
        raise "cannot reply to: empty reply channel" unless @reply_to

        @manager.publish(@reply_to, content, headers: headers)
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
