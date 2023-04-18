require_relative "./manager"

module Verse
  module Event
    # This is a simplified event manager for test environment,
    # it run locally (in the process) and cannot communicate with other services.
    class LocalEventManager < Verse::Event::Manager
      attr_reader :subscriptions

      def initialize(service_name, config = nil, logger = Logger.new($stdout))
        super

        @subscriptions = {}
      end

      def subscribe(channel, method = :jetstream, priority: nil, ack_type: nil, &block)
        return if @config&.fetch(:disable_subscription, nil)

        regexp = Regexp.new(
          "^" +
          channel.gsub(".", "\\.").gsub("?", "[^\.]+").gsub("*", ".*") +
          "$"
        )

        add_to_subscription_list(regexp) do |message, subject|
          block.call(message, subject)
        end
      end

      def stop
        @subscriptions.clear
      end

      def request(channel, content, headers: {}, reply_to: nil, timeout: 0.05)
        reply_to = "_reply.#{SecureRandom.hex}"

        out = nil

        subscribe(reply_to) do |message|
          @subscriptions.delete(reply_to) # Remove the subscription once a message is caught.
          out = message
        end

        Timeout.timeout(timeout) do
          message = Message.new(self, content, headers: headers, reply_to: reply_to)

          @subscriptions.each do |pattern, subscribers|
            next unless pattern.match?(channel)

            sub = subscribers.first

            if sub
              sub.call(message, channel)
              return out
            end
          end

          raise Timeout::Error # pretend we timed out.
        end
      end

      def request_all(channel, body: {}, headers: {}, reply_to: nil, timeout: 0.5)
        # Fake request all behavior
        begin
          out = []
          Timeout.timeout(timeout) do
            out << request(channel, body: body, headers: headers, timeout: timeout)
            sleep
          end
        rescue Timeout::Error
          # Do nothing, we always timeout; same behavior into NATS EM
        end

        # Return array with one item only,
        # or empty array if nothing reply to this message.
        out
      end

      # Publish a message to a specific channel
      #
      # @param channel [String] The channel to publish to
      # @param body [Hash] The payload of the message
      # @param headers [Hash] The headers of the message (if any)
      # @param reply_to [String] The reply_to of the message (if any)
      def publish(channel, content, headers: {}, reply_to: nil)
        message = Message.new(self, content, headers: headers, reply_to: reply_to)

        @subscriptions.each do |pattern, subscribers|
          next unless pattern.match?(channel)

          subscribers.each do |s|
            s.call(message, channel)
          end
        end
      end

      private

      def add_to_subscription_list(regexp, &block)
        @subscriptions[regexp] ||= []
        @subscriptions[regexp] << block
      end

    end
  end
end
