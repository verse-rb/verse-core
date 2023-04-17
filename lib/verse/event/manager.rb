module Verse
  module Event
    module Manager

      MODE_BROADCAST = :broadcast
      MODE_CONSUMER  = :consumer
      MODE_COMMAND   = :command


      # Publish an event to a specific channel.
      def publish(channel, payload, headers: {})
        #:nocov:
        raise NotImplementedError, "please implement request"
        #:nocov:
      end

      # Send request to a specific channel
      # @param channel [String] The channel to send the request to
      # @param payload [Hash] The payload of the request
      # @param headers [Hash] The headers of the message (if any)
      # @param timeout [Float] The timeout of the request
      # @return Promise<[Hash]> The response of the request
      # @raise [Verse::Error::Timeout] If the request timed out
      def request(channel, payload: {}, headers: {}, timeout: 0.5)
        #:nocov:
        raise NotImplementedError, "please implement request"
        #:nocov:
      end

      # Send request to multiple subscribers. Wait until timeout and
      # return an array of responses.
      # @param channel [String] The channel to send the request to
      # @param payload [Hash] The payload of the request
      # @param headers [Hash] The headers of the message (if any)
      # @param timeout [Float] The timeout of the request
      # @return Promise<[Array<Hash>]> The responses of the request
      def request_all(channel, payload: {}, headers: {}, timeout: 0.5)
        #:nocov:
        raise NotImplementedError, "please implement request_all"
        #:nocov:
      end


      # Subscribe to a specific channel in a specific mode
      # @param channel [String] The channel to subscribe to
      # @param mode [Symbol] The mode of the subscription
      # @param block [Proc] The block to execute when a message is received
      # @return [Verse::Event::Subscription] The subscription object
      def subscribe(channel, mode = MODE_CONSUMER, &block)
        #:nocov:
        raise NotImplementedError, "please implement subscribe"
        #:nocov:
      end

    end
  end
end
